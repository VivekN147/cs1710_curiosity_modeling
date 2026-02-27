# CSCI 1710 - Curiosity Modeling

> As part of your project submission, we request a one page `README.md` file that provides a comprehensive overview of your implementation. This document should effectively communicate your approach and insights to someone who might be new to your chosen topic.

> Your `README.md` should not only serve as a guide to your project but also reflect your understanding and the thought process behind your modeling decisions.

## 1: Project Objective

> **Project Objective:** What are you trying to model? Include a brief description that would give someone unfamiliar with the topic a basic understanding of your goal.

We are primarily trying to model the Brown course registration system from a student's perspective, including having to deal with concentration requirements, prerequisite courses, enrollment limits, and more. The goal is to determine an effective course plan for the student given these requirements to ensure an on-time graduation.

## 2: Model Design and Visualization

> **Model Design and Visualization:** Give an overview of your model design choices, what checks or run statements you wrote, and what we should expect to see from an instance produced by the Sterling visualizer. How should we look at and interpret an instance created by your spec? Did you create a custom visualization, or did you use the default?

The model uses multiple predicates to enforce both wellformedness as well as adherence to prerequisistes, concentration requirements, and enrollment caps. There is a run statement that includes all the wellformedness predicates and requirement predicates and ensures there is exactly 1 `Student`, `CoursePlan`, and `ConcentrationReqs`. We created a custom visualization, so the Sterling Visualizer should show a `Student` that has both a `CoursePlan` and a `ConcentrationReqs` directly to the east and west respectively. The `CoursePlan` will point to `Semsester`s, which can point to other `Semeseter`s. Each `Semester` has a field for the courses taken, and all the courses that are a field of `ConcentrationReqs` will be in those `Semester`s. `Course`s are also present to show the enrollment caps and the prereqs if any. An instance created by our spec shows a valid plan of courses to take through some amount of semesters such that all the concentration requirements are met, prerequisites are respected, and enrollment caps aren't violated.

A second run statement was also added, which simply shows a more complicated scenario involving `prereqs`, multiple `Student`s, more `Semester`s, etc. The custom visualization struggles somewhat here but the general structure of a `CoursePlan` pointing to successive `Semester`s remains, as do the inner partial function fields.

Of note, we treated modeling the basic logic of a singular `Student` who takes courses in a `CoursePlan` as our base goal; additional functionality for this single student such as course load, duplication, and prereq constraints was considered our target goal; and full interaction with other `Student`s and `enrollmentCap`s was our stretch goal. While we implemented the full functionality for our base and target goals, we ran out of time to sucessfully implement full interaction between `Student`s. In particular, we did not add `sigs`/fields representing years and fall or spring classification to assign to `Semester`s, so Forge models the `Semester`s as per-student and caps are never challenged in practice. We did, however, implement the basic structure of an `enrollmentCap` and the basic ideass it must satisfy. A complete implementation of our stretch goal, combined with perhaps replacing partial functions with `sets` in relational Forge, along with our stretch-strech goal of complex boolean valued `prereq`s (like Brown has for intro CS), could make for an interesting final project.

## 3: Signatures and Predicates

> **Signatures and Predicates:** At a high level, what do each of your sigs and preds represent in the context of the model? Justify the purpose for their existence and how they fit together.

### `sig`s

`sig Student` will represent a student and will have field `ConcentrationReqs` and `CoursePlan`.

`sig ConcentrationReqs` will represent concentration requirements, and it will contain a pfunc mapping `Course`s to `Boolean`s.

`sig Course` will represent an individual course, with fields `enrollmentCap` (number) and a pfunc mapping `Course`s to `Boolean`s. Optionally will later add fall/spring restrictions and more complex boolean logic with prerequisite courses (stretch and stretch-stretch goals [and final project ideas], respectively).

`sig CoursePlan` will be have a "first" field representing the first `Semester`.

`sig Semester` will represent a `Semester` that has a "next" field to another `Semester`, as well as a pfunc mapping `Course`s to `Boolean`s.

### `Pred`s

`wellFormedPlan` ensures that there are no `Semester` can reach itself in the plan (i.e., no loops) and that all `Semester`s are included in a `CoursePlan`.

`wellFormedCourses` ensures that the cap of `Course`s is greater than 0 (a `Course` should not allow in 0 or a negative number of people).

`validCourseLoad` ensures every `Semester` building block of a plan has between 3 and 5 courses.

`noDuplicateCourses` ensures there are a single course is not located in two `Semester's` of a student's plan.

`courseInSemester` ensures that given a `Course` and a `Semseter`, that course is taken in that `Semester`.

`semesterInPlan` ensures that a `Semester` is within a `CoursePlan` either by being the first `Semester` or being reachable via next.

`semesterBefore` ensures that a `Semester` comes directly before another `Semester`.

`takenBefore` ensures that a `Course` was taken in a `Semester` before the current `Semester`.

`SatisfiesPrereqs` ensures that for every `Course` a student takes in their `CoursePlan`, all the prereqs must have been taken in a strictly earlier `Semester`.

`SatisifiesConcentrationReqs` ensures that every `Course` required by the student's concentration appears somewhere in the course plan.

`SatisfiesCaps` ensures that the number of students enrolled in a `Course` doesn't exceed the enrollment cap of the `Course`.

At a high level, we specified the following (used to generate our `pred`s):

- require that for a student to add a course, the prereqs will need to be satisfied
- basic array well-formedness for the course plan in terms of taken courses
- enrollment cap must not be exceeded
- all concentration requirements must be met in the given number of semesters
- well formedness enrollment has to be positive
- a student cannot take a course twice
- student can take 3-5 courses per semester

## 4: Testing

> **Testing:** What tests did you write to test your model itself? What tests did you write to verify properties about your domain area? Feel free to give a high-level overview of this.

We wrote numerous tests for our model. We wrote unit example and assert statements for all predicates, testing both overconstraint and underconstraint bugs. For instance, we tested that `wellFormedCourses` would not allow any kind of cycle, whether direct or indirect, and that while `noDuplicateCourses` forbids courses from appearing multiple times in the same student's course plan, the same course could appear in different student's course plans. We also tested combinations of predicates, including that our well formed predicates were all satisfiable together to ensure that interaction did not accidentally cause any issues. Testing for the requirement predicates involved testing whether prereqs where satisfied or not, whether course requirements had been met, and if enrollment caps had been violated. This also included testing edge cases like if prereqs were taken in the same semester as the course and required courses being taken in semesters that were not in the course plan. These requirement predicates were also tested in combination with the wellformedness predicates.

## 5: Documentation

> **Documentation:** Make sure your model and test files are well-documented. This will help in understanding the structure and logic of your project.

This is done.
