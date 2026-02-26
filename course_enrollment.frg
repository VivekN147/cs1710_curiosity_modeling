#lang forge/froglet

option run_sterling "course_enrollment.cnd"

-- modeling booleans
abstract sig Boolean {}
one sig True, False extends Boolean {}

-- a course offered by the university
sig Course {
    enrollmentCap: one Int,
    prereqs: pfunc Course -> Boolean
}

-- concentration requirements
sig ConcentrationReqs {
    required_courses: pfunc Course -> Boolean
}

-- a semester in the plan
sig Semester {
    next: lone Semester,
    courses: pfunc Course -> Boolean
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

-- To be well formed, there can be no semester loops, and all semesters must be in the plan
pred wellFormedPlan {
  -- semester not reachable form itself
  all s: Semester | {
    not reachable[s, s, next]
  }
  
  -- semester is either first in course plan
  -- or reachable from the first one
  all s: Semester | {
    some cp: CoursePlan | {
      s = cp.first or reachable[s, cp.first, next]
    }
  }
}

-- Cap must be greater than or equal to zero to be well formed
pred wellFormedCourses {
  all c: Course | c.enrollmentCap > 0
}

-- To be a valid course load in a semester, there must be between 3 and 5 courses
pred validCourseLoad {
  all s: Semester | {
    -- for all semesteres, must be both more than or equal to 3 courses
    -- and less then or equal to 5 courses
    #{c: Course | courseInSemester[s, c]} >= 3
    #{c: Course | courseInSemester[s, c]} <= 5
  }
}

-- No course can be taken in two distinct semesters for a student's course plan
pred noDuplicateCourses {
  all st: Student | {
    all s1, s2: Semester | {
      -- for all students and every pair of semesters, if both semesters
      -- are in the students plan, this implies...
      (semesterInPlan[st, s1] and semesterInPlan[st, s2] and s1 != s2) implies {
        no c: Course | {
          -- there are no courses in both semesters
          courseInSemester[s1, c] and courseInSemester[s2, c]
        }
      }
    }
  }
}

run {
  SatisfiesPrereqs
  SatisfiesConcentrationReqs
  SatisfiesCaps

  wellFormedPlan
  wellFormedCourses
  validCourseLoad
  noDuplicateCourses
} for 4 Int, exactly 1 Student, exactly 1 CoursePlan, exactly 1 ConcentrationReqs