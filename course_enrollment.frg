#lang forge/froglet

-- a course offered by the university
sig Course {
    enrollmentCap: one Int,
    prereq_1: lone Course,
    prereq_2: lone Course,
    prereq_3: lone Course
    -- add more prereqs as desired
}

-- concentration requirements
sig ConcentrationReqs {
    course_a: lone Course,
    course_b: lone Course,
    course_c: lone Course,
    course_d: lone Course
    -- add more concentration requirements as desired
}

-- a semester in the plan
sig Semester {
    next: pfunc Semester -> Semester,
    courses: pfunc Int -> Course,
    lastIndex: one Int
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
