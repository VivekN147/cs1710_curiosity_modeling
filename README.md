# cs1710_curiosity_modeling

What do we want to model?
* Given a student aiming to get some degree, plan out courses such that the student earns that degree while taking into account prerequisites and class sizes such that the course plan is feasible.

From LLM:

Make the Idea Technically Well-Defined

Right now the scope is slightly broad. Consider pinning down:
* Core entities (likely minimum model)
* Student
* Course
* Term/Semester
* Degree requirements
* Prerequisite relation
* Course capacity
* Schedule/plan

Key questions your model should answer

Pick 2–4 concrete ones, for example:
* Does a valid graduation plan exist within N semesters?
* Can over-enrollment occur?
* Are prerequisite chains always respected?
* What is the minimum number of semesters needed?

Be precise about capacity

Decide early:
* Is capacity global per course offering?
* Are multiple sections modeled or ignored?
* Is enrollment first-come or just a constraint?

Start simple: one offering per course per term with a fixed cap.

Potential Modeling Pitfalls

These are the most likely trouble spots for a first Forge project:
Prerequisite semantics
Common ambiguity:
* Must prereqs be completed in strictly earlier terms?
* Can they be taken concurrently?
* Are prereqs AND or OR?

Advice: Start with AND + strictly earlier term. Expand later.

Time modeling

Students often overcomplicate semesters.
Watch for:
* Overly detailed calendars
* Complex ordering relations
* Unbounded term counts

Advice:
Model terms as a simple linear sequence of fixed length.
* Degree requirements explosion
* Degree rules can become messy fast:
- Categories (e.g., electives vs core)
- Credit counts
- Multiple requirement types

Advice:
Start with:
* Required course set
* Maybe one elective bucket
* Add realism only if the core model is stable.

Capacity + multiple students
* If you model many students early, the state space can blow up.

Advice:
Start with one student, verify correctness, then optionally scale.

Optimization vs feasibility

Forge is best at validity and counterexamples, not heavy optimization.
Avoid initially:
* “best schedule”
* “minimum time” with complex objectives

Instead start with:
* “exists a valid plan within k terms”

## 3: Sigs and Preds
`sig Student{}` will represent a student and will have field `ConcentrationReqs` and `CoursePlan`.

`sig ConcentrationReqs` will represent concentration requirements, and it will contain fields like `course_a`, `course_b`, ... etc., with each of those being `lone`.

`sig Course` will represent an individual course, with fields `enrollmentCap` (number) and `prereq_1`, `prereq_2` (Course), etc. Optionally will later add fall/spring restrictions and more complex boolean logic with prerequisite courses.

`sig CoursePlan` will be similar to the lab 2 object with a "next" field representing successive semesters and a partial function representing an array like the binary search example from lecture.

At a high level, we will specify
- require that for a student to add a course, the prereqs will need to be satisfied
- basic array well-formedness for the course plan in terms of taken courses
- enrollment cap must not be exceeded
- all concentration requirements must be met in the given number of semesters
- well formedness enrollment has to be positive
- a student cannot take a course twice
- student can take 3-5 (or we can change this) courses per semester

Gemini Suggestions on Labor Division
This sounds like a fantastic CS1710 final project! Modeling a degree planner in Forge is a classic but challenging problem, primarily because the state space can blow up quickly if you aren't careful with your time/semester bounds. Adhering to the "start simple" advice from your context block is the best way to ensure your model actually runs without timing out the solver.

Let's formalize your high-level constraints into clear, distinct predicates, and then establish a logical division of labor for two people.

### Part 1: Defining the Predicates

To keep the model clean, we should separate structural well-formedness (making sure the data structures are valid) from the domain logic (the actual university rules).

Here are the clear predicate definitions based on your constraints:

**Structural & Well-Formedness Predicates**

* **`wellFormedPlan`**: Ensures the `CoursePlan` acts like a proper sequence of semesters. It enforces that the `next` relation forms a simple linear sequence (no loops, no branching) and that your partial function correctly maps semesters to the set of courses taken.
* **`wellFormedCourses`**: Enforces basic course properties, specifically that `enrollmentCap > 0` for all courses.

**Domain Logic (University Rules) Predicates**

* **`validCourseLoad`**: Ensures that for any given semester in the `CoursePlan`, the cardinality of the courses assigned is between  and .
* **`noDuplicateCourses`**: Ensures that the intersection of courses taken in any two distinct semesters is empty, meaning a student cannot take a course twice.
* **`prereqsSatisfied`**: The most complex rule. For any course  taken in semester , all prerequisites (`prereq_1`, `prereq_2`) must belong to some semester  that strictly precedes  in the `CoursePlan`'s sequence.
* **`reqsMet`**: Ensures that by the final semester in the `CoursePlan`, the union of all courses taken across all semesters contains all the courses specified in the student's `ConcentrationReqs`.
* **`capsRespected`**: Ensures that the total number of students enrolled in any course during a specific semester does not exceed that course's `enrollmentCap`. *(Note: If you are starting with just 1 Student to keep the model simple, this predicate will pass trivially, but it's good to write it so it scales when you introduce `sig Student` as a set).*

---

### Part 2: Divvying Up the Work

A great way to split this project in Forge is by separating the **State/Structural Logistics** from the **Rules/Constraints**. This allows both partners to work in parallel without stepping on each other's toes.

| Task Category | Assginee | Responsibilities | Why this makes sense |
| --- | --- | --- | --- |
| **Data Structures & State** | **Person A** | • Write all `sig` definitions (`Student`, `Course`, `CoursePlan`, `ConcentrationReqs`).<br>

<br>• Write `wellFormedPlan` and `wellFormedCourses`.<br>

<br>• Write `validCourseLoad` and `noDuplicateCourses`. | Person A focuses on making sure the "board is set up correctly." Dealing with Forge partial functions and linear traces (`next`) can be tricky, so one person should own the "semester array" logic. |
| **Business Logic & Relations** | **Person B** | • Write `prereqsSatisfied`.<br>

<br>• Write `reqsMet`.<br>

<br>• Write `capsRespected`.<br>

<br>• Set up the final `run` statements and test cases. | Person B focuses on relational algebra and graph traversal (e.g., using transitive closures like `^next` or `*next` to check prerequisites) and set theory (checking subsets for concentration requirements). |

**Integration Phase (Together):**
Once Person A has the semesters advancing correctly and Person B has the rules written, you pair-program the final `pred graduationIsPossible` which just `and`s all your predicates together, and use Forge to search for an instance.

---

Would you like me to help draft the actual Forge/Alloy syntax for any of these specific predicates, such as the `prereqsSatisfied` relation or the `CoursePlan` partial function?
