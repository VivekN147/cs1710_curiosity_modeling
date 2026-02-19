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
