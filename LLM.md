> This file contains the conversations we had with LLMs about our project

## LLM Advice and Notes

From LLM:

Make the Idea Technically Well-Defined

Right now the scope is slightly broad. Consider pinning down:

- Core entities (likely minimum model)
- Student
- Course
- Term/Semester
- Degree requirements
- Prerequisite relation
- Course capacity
- Schedule/plan

Key questions your model should answer

Pick 2–4 concrete ones, for example:

- Does a valid graduation plan exist within N semesters?
- Can over-enrollment occur?
- Are prerequisite chains always respected?
- What is the minimum number of semesters needed?

Be precise about capacity

Decide early:

- Is capacity global per course offering?
- Are multiple sections modeled or ignored?
- Is enrollment first-come or just a constraint?

Start simple: one offering per course per term with a fixed cap.

Potential Modeling Pitfalls

These are the most likely trouble spots for a first Forge project:
Prerequisite semantics
Common ambiguity:

- Must prereqs be completed in strictly earlier terms?
- Can they be taken concurrently?
- Are prereqs AND or OR?

Advice: Start with AND + strictly earlier term. Expand later.

Time modeling

Students often overcomplicate semesters.
Watch for:

- Overly detailed calendars
- Complex ordering relations
- Unbounded term counts

Advice:
Model terms as a simple linear sequence of fixed length.

- Degree requirements explosion
- Degree rules can become messy fast:

* Categories (e.g., electives vs core)
* Credit counts
* Multiple requirement types

Advice:
Start with:

- Required course set
- Maybe one elective bucket
- Add realism only if the core model is stable.

Capacity + multiple students

- If you model many students early, the state space can blow up.

Advice:
Start with one student, verify correctness, then optionally scale.

Optimization vs feasibility

Forge is best at validity and counterexamples, not heavy optimization.
Avoid initially:

- “best schedule”
- “minimum time” with complex objectives

Instead start with:

- “exists a valid plan within k terms”

### AI Citation

AI was used in accordance with the initial task to help us both choose and then develop our idea. We used Gemini with the given prompt and to help us further realize the details by turning our list of desired properties into predicate names around which we could organize our implementation. We also used AI to fix syntax and other low-level issues with Froglet programming in our constraints.

## Gemini Suggestions on Labor Division:

This sounds like a fantastic CS1710 final project! Modeling a degree planner in Forge is a classic but challenging problem, primarily because the state space can blow up quickly if you aren't careful with your time/semester bounds. Adhering to the "start simple" advice from your context block is the best way to ensure your model actually runs without timing out the solver.

Let's formalize your high-level constraints into clear, distinct predicates, and then establish a logical division of labor for two people.

### Part 1: Defining the Predicates

To keep the model clean, we should separate structural well-formedness (making sure the data structures are valid) from the domain logic (the actual university rules).

Here are the clear predicate definitions based on your constraints:

**Structural & Well-Formedness Predicates**

- **`wellFormedPlan`**: Ensures the `CoursePlan` acts like a proper sequence of semesters. It enforces that the `next` relation forms a simple linear sequence (no loops, no branching) and that your partial function correctly maps semesters to the set of courses taken.
- **`wellFormedCourses`**: Enforces basic course properties, specifically that `enrollmentCap > 0` for all courses.

**Domain Logic (University Rules) Predicates**

- **`validCourseLoad`**: Ensures that for any given semester in the `CoursePlan`, the cardinality of the courses assigned is between and .
- **`noDuplicateCourses`**: Ensures that the intersection of courses taken in any two distinct semesters is empty, meaning a student cannot take a course twice.
- **`prereqsSatisfied`**: The most complex rule. For any course taken in semester , all prerequisites (`prereq_1`, `prereq_2`) must belong to some semester that strictly precedes in the `CoursePlan`'s sequence.
- **`reqsMet`**: Ensures that by the final semester in the `CoursePlan`, the union of all courses taken across all semesters contains all the courses specified in the student's `ConcentrationReqs`.
- **`capsRespected`**: Ensures that the total number of students enrolled in any course during a specific semester does not exceed that course's `enrollmentCap`. _(Note: If you are starting with just 1 Student to keep the model simple, this predicate will pass trivially, but it's good to write it so it scales when you introduce `sig Student` as a set)._

---

### Part 2: Divvying Up the Work

A great way to split this project in Forge is by separating the **State/Structural Logistics** from the **Rules/Constraints**. This allows both partners to work in parallel without stepping on each other's toes.

Here is the content converted into a valid Markdown table:

| Task Category                  | Assignee     | Responsibilities                                                                                                                                                                                    | Why this makes sense                                                                                                                                                                                          |
| ------------------------------ | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Data Structures & State**    | **Person A** | • Write all `sig` definitions (`Student`, `Course`, `CoursePlan`, `ConcentrationReqs`).<br>• Write `wellFormedPlan` and `wellFormedCourses`.<br>• Write `validCourseLoad` and `noDuplicateCourses`. | Person A focuses on making sure the “board is set up correctly.” Dealing with Forge partial functions and linear traces (`next`) can be tricky, so one person should own the “semester array” logic.          |
| **Business Logic & Relations** | **Person B** | • Write `prereqsSatisfied`.<br>• Write `reqsMet`.<br>• Write `capsRespected`.<br>• Set up the final `run` statements and test cases.                                                                | Person B focuses on relational algebra and graph traversal (e.g., using transitive closures like `^next` or `*next` to check prerequisites) and set theory (checking subsets for concentration requirements). |

**Integration Phase (Together):**
Once Person A has the semesters advancing correctly and Person B has the rules written, you pair-program the final `pred graduationIsPossible` which just `and`s all your predicates together, and use Forge to search for an instance.

---

Would you like me to help draft the actual Forge/Alloy syntax for any of these specific predicates, such as the `prereqsSatisfied` relation or the `CoursePlan` partial function?