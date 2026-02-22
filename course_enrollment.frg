#lang forge/froglet

option run_sterling "course_enrollment.cnd"

-- using these to model sets with pfuncs, maybe we switch to relational Forge with permission?
abstract sig Boolean {}
one sig True, False extends Boolean {}

-- a course offered by the university
sig Course {
    enrollmentCap: one Int,
    // prereq_1: lone Course,
    // prereq_2: lone Course,
    // prereq_3: lone Course
    prereqs: pfunc Course -> Boolean
    -- add more prereqs as desired
    -- Vivek's Note: I made this a pfunc since adding more prereqs doesn't scale great
}

-- concentration requirements
sig ConcentrationReqs {
    // course_a: lone Course,
    // course_b: lone Course,
    // course_c: lone Course,
    // course_d: lone Course
    required_courses: pfunc Course -> Boolean
    -- add more concentration requirements as desired
    -- Vivek's Note: I made this a pfunc since adding more concentration reqs doesn't scale great
}

-- a semester in the plan
sig Semester {
    next: lone Semester,
    courses: pfunc Course -> Boolean
    // lastIndex: one Int
    -- Vivek's Note: instead of using lastIndex to find where the last semester is, we can use "lone" and just check some/none
}

-- points to a starting semester
sig CoursePlan {
    first: lone Semester
}

-- student who can take courses
sig Student {
    concentration: one ConcentrationReqs,
    plan: one CoursePlan
}


-- Helper: get all courses taken in a given semester
pred courseInSemester[s: Semester, c: Course] {
    s.courses[c] = True
}

-- Helper: get all semesters reachable from the plan's first semester (i.e., all semesters in the plan)
pred semesterInPlan[st: Student, s: Semester] {
    some st.plan.first and
    (s = st.plan.first or reachable[s, st.plan.first, next])
}

-- Helper: s1 comes strictly before s2 in the chain
pred semesterBefore[s1: Semester, s2: Semester] {
    reachable[s2, s1, next]
}

-- Helper: course c was taken by student st in some semester strictly before s
pred takenBefore[st: Student, c: Course, s: Semester] {
    some sPrev: Semester | {
        semesterInPlan[st, sPrev]
        semesterBefore[sPrev, s]
        courseInSemester[sPrev, c]
    }
}

-- For every course a student takes in their plan, all prereqs must have been taken in a strictly earlier semester
-- Future case: If we want to represent coreqs in our model, something will have to change
pred SatisfiesPrereqs {
    all st: Student | {
        all s: Semester | {
            semesterInPlan[st, s] implies {
                all c: Course | {
                    courseInSemester[s, c] implies {
                        -- every prereq of c must have been taken before this semester
                        all prereq: Course | {
                            c.prereqs[prereq] = True => takenBefore[st, prereq, s]
                        }
                    }
                }
            }
        }
    }
}

-- Every course required by the student's concentration must appear somewhere in their plan
pred SatisfiesConcentrationReqs {
    all st: Student | {
        all c: Course | {
            st.concentration.required_courses[c] = True implies {
                some s: Semester | {
                    semesterInPlan[st, s]
                    courseInSemester[s, c]
                }
            }
        }
    }
}

-- The number of students enrolled in each course in each semester must not exceed that course's enrollmentCap
pred SatisfiesCaps {
    all s: Semester, c: Course | {
        -- the set of students taking c in s has cardinality <= cap
        #{st: Student | semesterInPlan[st, s] and courseInSemester[s, c]}
            <= c.enrollmentCap
    }
}

run {
    SatisfiesPrereqs
    SatisfiesConcentrationReqs
    SatisfiesCaps
} for 4 Int, exactly 1 Student, exactly 1 CoursePlan, exactly 1 ConcentrationReqs