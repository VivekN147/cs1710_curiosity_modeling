#lang forge/froglet

open "course_enrollment.frg"


test suite for wellFormedCourses {

  // examples
  example validCap is wellFormedCourses for {
    Course = `C1 + `C2
    `C1.enrollmentCap = 7
    `C2.enrollmentCap = 5
  }

  example invalidCapZero is {not wellFormedCourses} for {
    Course = `C1
    `C1.enrollmentCap = 0 // bad
  }

  // asserts
  assert {
    wellFormedCourses
  } is sat

  // If wellFormedCourses holds, no course can have a negative cap
  assert {
    wellFormedCourses
    some c: Course | {
      c.enrollmentCap < 0
    }
  } is unsat

  // If wellFormedCourses holds, no course can have a zero cap
  assert {
    wellFormedCourses
    some c: Course | {
      c.enrollmentCap = 0
    }
  } is unsat

  // If all courses have > 0 cap, wellFormedCourses must be satisfied
  assert {
    not wellFormedCourses
    all c: Course | {
      c.enrollmentCap > 0
    }
  } is unsat
}


test suite for wellFormedPlan {

  // examples
  example validLinearPlan is wellFormedPlan for {
    CoursePlan = `Plan1
    Semester = `S1 + `S2
    `Plan1.first = `S1
    `S1.next = `S2
    no `S2.next
  }

  example invalidLoopingPlan is {not wellFormedPlan} for {
    CoursePlan = `Plan1
    Semester = `S1 + `S2
    `Plan1.first = `S1
    `S1.next = `S2
    `S2.next = `S1
  }

  example invalidOrphanSemester is {not wellFormedPlan} for {
    CoursePlan = `Plan1
    Semester = `S1 + `Orphan
    `Plan1.first = `S1
    no `S1.next
    no `Orphan.next
  }

  // asserts
  assert {
    wellFormedPlan
  } is sat

  // No self-loops
  assert {
    wellFormedPlan
    some s: Semester | {
      s.next = s
    }
  } is unsat

  // No reachable cycles
  assert {
    wellFormedPlan
    some s: Semester | {
      reachable[s, s, next]
    }
  } is unsat

  // There can be no "orphan" semesters completely disconnected from a plan
  assert {
    wellFormedPlan
    some s: Semester | all cp: CoursePlan | {
      s != cp.first and not reachable[s, cp.first, next]
    }
  } is unsat
}


test suite for validCourseLoad {

  // examples
  example validLoadof4courses is validCourseLoad for {
    Semester = `S1
    Course = `C1 + `C2 + `C3 + `C4
    Boolean = `True + `False
    True = `True
    False = `False
    
    `S1.courses = `C1 -> `True + 
                  `C2 -> `True + 
                  `C3 -> `True + 
                  `C4 -> `True
  }

  example invalidLoadUnderflow is {not validCourseLoad} for {
    Semester = `S1
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False
    
    `S1.courses = `C1 -> `True + 
                  `C2 -> `True
  }

  // asserts
  assert {
    validCourseLoad
  } is sat

  // No semester can exist with strictly fewer than 3 courses mapped to True
  assert {
    validCourseLoad
    some s: Semester | {
      #{c: Course | s.courses[c] = True} < 3
    }
  } is unsat

  // No semester can exist with strictly greater than 5 courses mapped to True
  assert {
    validCourseLoad
    some s: Semester | {
      #{c: Course | s.courses[c] = True} > 5
    }
  } is unsat

  // If a semester maps 6 distinct courses to True, should fail
  assert {
    validCourseLoad
    some s: Semester | {
      some disj c1, c2, c3, c4, c5, c6: Course | {
        s.courses[c1] = True
        s.courses[c2] = True
        s.courses[c3] = True
        s.courses[c4] = True
        s.courses[c5] = True
        s.courses[c6] = True
      }
    }
  } is unsat
}


test suite for noDuplicateCourses {

  // examples
  example validNoDupes is noDuplicateCourses for {
    Student = `Stu1
    CoursePlan = `Plan1
    Semester = `S1 + `S2
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Plan1.first = `S1
    `S1.next = `S2
    no `S2.next

    // C1 in S1, C2 in S2. No overlap.
    `S1.courses = `C1 -> `True
    `S2.courses = `C2 -> `True
  }

  example invalidDupes is {not noDuplicateCourses} for {
    Student = `Stu1
    CoursePlan = `Plan1
    Semester = `S1 + `S2
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Plan1.first = `S1
    `S1.next = `S2
    no `S2.next

    // C1 taken in both S1 and S2
    `S1.courses = `C1 -> `True
    `S2.courses = `C1 -> `True
  }

  // asserts
  assert {
      noDuplicateCourses
  } is sat

  // If noDuplicateCourses holds, we should not find a student whose plan includes two semesters containing the same course
  assert {
    noDuplicateCourses
    some st: Student, c: Course | {
      some disj s1, s2: Semester | {
        semesterInPlan[st, s1]
        semesterInPlan[st, s2]
        courseInSemester[s1, c]
        courseInSemester[s2, c]
      }
    }
  } is unsat

  // If a student does take the same course in two distinct reachable semesters, noDuplicateCourses should evaluate to false.
  assert {
    not noDuplicateCourses
    all st: Student | {
      all disj s1, s2: Semester | {
        (semesterInPlan[st, s1] and semesterInPlan[st, s2]) implies {
          no c: Course | courseInSemester[s1, c] and courseInSemester[s2, c]
        }
      }
    }
  } is unsat

  // Ok if two different students take the same course in different semesters.
  assert {
    noDuplicateCourses
    some disj st1, st2: Student | {
      some disj s1, s2: Semester {
        some c: Course | {
          semesterInPlan[st1, s1]
          semesterInPlan[st2, s2]
          courseInSemester[s1, c]
          courseInSemester[s2, c]
        }
      }
    }
  } is sat

  // combos
  // all combined is sat
  assert {
    wellFormedCourses
    wellFormedPlan
    validCourseLoad
    noDuplicateCourses
  } is sat

  // system with valid bounds but forced invalid plan topology should be unsat
  assert {
    wellFormedCourses
    validCourseLoad
    noDuplicateCourses
    wellFormedPlan
    // bad cycle
    some s: Semester | s.next = s 
  } is unsat
}

test suite for SatisfiesPrereqs {

  -- A student takes C2 in S2 and its only prereq (C1) was taken in S1
  example prereqTakenEarlier is SatisfiesPrereqs for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1 + `S2
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    `S1.next = `S2
    no `S2.next

    no `C1.prereqs
    `C2.prereqs = `C1 -> `True

    `S1.courses = `C1 -> `True
    `S2.courses = `C2 -> `True

    no `Conc1.required_courses
    `C1.enrollmentCap = 5
    `C2.enrollmentCap = 5
  }

  -- A student takes C2 in S1 but its prereq C1 has not been taken yet
  example prereqNotTaken is {not SatisfiesPrereqs} for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1 + `S2
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    `S1.next = `S2
    no `S2.next

    no `C1.prereqs
    `C2.prereqs = `C1 -> `True

    `S1.courses = `C2 -> `True
    `S2.courses = `C1 -> `True

    no `Conc1.required_courses
    `C1.enrollmentCap = 5
    `C2.enrollmentCap = 5
  }

  -- A student takes C2 in the same semester as its prereq C1
  example prereqSameSemester is {not SatisfiesPrereqs} for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    no `C1.prereqs
    `C2.prereqs = `C1 -> `True

    `S1.courses = `C1 -> `True + `C2 -> `True

    no `Conc1.required_courses
    `C1.enrollmentCap = 5
    `C2.enrollmentCap = 5
  }

  -- A course with no prereqs can be taken freely
  example noPrereqs is SatisfiesPrereqs for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    no `C1.prereqs
    `S1.courses = `C1 -> `True

    no `Conc1.required_courses
    `C1.enrollmentCap = 5
  }

  assert { SatisfiesPrereqs } is sat

  -- If SatisfiesPrereqs holds, no student takes a course whose prereq they
  -- haven't taken in an earlier semester
  assert {
    SatisfiesPrereqs
    some st: Student, s: Semester, c: Course, prereq: Course | {
      semesterInPlan[st, s]
      courseInSemester[s, c]
      c.prereqs[prereq] = True
      not takenBefore[st, prereq, s]
    }
  } is unsat

  -- A prereq taken in a later semester does not satisfy the requirement
  assert {
    SatisfiesPrereqs
    some st: Student, c: Course, prereq: Course | {
      some disj sEarly, sLate: Semester | {
        semesterInPlan[st, sEarly]
        semesterInPlan[st, sLate]
        semesterBefore[sEarly, sLate]
        courseInSemester[sLate, c]
        c.prereqs[prereq] = True
        courseInSemester[sEarly, prereq]
      }
    }
  } is sat

  -- Prereq taken in the same semester is insufficient
  assert {
    SatisfiesPrereqs
    some st: Student, s: Semester, c: Course, prereq: Course | {
      semesterInPlan[st, s]
      courseInSemester[s, c]
      courseInSemester[s, prereq]
      c.prereqs[prereq] = True
      no sPrev: Semester | {
        semesterInPlan[st, sPrev]
        semesterBefore[sPrev, s]
        courseInSemester[sPrev, prereq]
      }
    }
  } is unsat

  -- SatisfiesPrereqs is compatible with all other predicates
  assert {
    SatisfiesPrereqs
    SatisfiesConcentrationReqs
    SatisfiesCaps
    wellFormedPlan
    wellFormedCourses
  } is sat
}

test suite for SatisfiesConcentrationReqs {

  -- Required course is taken somewhere in the plan
  example requiredCourseTaken is SatisfiesConcentrationReqs for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    `Conc1.required_courses = `C1 -> `True

    `S1.courses = `C1 -> `True

    no `C1.prereqs
    `C1.enrollmentCap = 5
  }

  -- Required course is never taken
  example requiredCourseNotTaken is {not SatisfiesConcentrationReqs} for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    `Conc1.required_courses = `C1 -> `True
    `S1.courses = `C2 -> `True

    no `C1.prereqs
    no `C2.prereqs
    `C1.enrollmentCap = 5
    `C2.enrollmentCap = 5
  }

  -- Required course taken in a later semester still satisfies
  example requiredCourseTakenLater is SatisfiesConcentrationReqs for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1 + `S2
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    `S1.next = `S2
    no `S2.next

    `Conc1.required_courses = `C1 -> `True
    `S1.courses = `C2 -> `True
    `S2.courses = `C1 -> `True

    no `C1.prereqs
    no `C2.prereqs
    `C1.enrollmentCap = 5
    `C2.enrollmentCap = 5
  }

  -- A concentration with no required courses is satisfied
  example noRequiredCourses is SatisfiesConcentrationReqs for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    no `Conc1.required_courses
    `S1.courses = `C1 -> `True

    no `C1.prereqs
    `C1.enrollmentCap = 5
  }

  -- asserts

  assert { SatisfiesConcentrationReqs } is sat

  -- If SatisfiesConcentrationReqs holds, every required course must appear
  -- in at least one semester of the student's plan
  assert {
    SatisfiesConcentrationReqs
    some st: Student, c: Course | {
      st.concentration.required_courses[c] = True
      no s: Semester | {
        semesterInPlan[st, s]
        courseInSemester[s, c]
      }
    }
  } is unsat

  -- A required course taken in a sememster NOT in the plan does not count
  assert {
    SatisfiesConcentrationReqs
    some st: Student, c: Course, s: Semester | {
      st.concentration.required_courses[c] = True
      courseInSemester[s, c]
      not semesterInPlan[st, s]
      no s2: Semester | semesterInPlan[st, s2] and courseInSemester[s2, c]
    }
  } is unsat

  -- Mapping a course to False in required_courses does not require it to be taken
  assert {
    SatisfiesConcentrationReqs
    some st: Student, c: Course | {
      st.concentration.required_courses[c] = False
      no s: Semester | semesterInPlan[st, s] and courseInSemester[s, c]
    }
  } is sat

  -- SatisfiesConcentrationReqs is compatible with all other predicates
  assert {
    SatisfiesPrereqs
    SatisfiesConcentrationReqs
    SatisfiesCaps
    wellFormedPlan
    wellFormedCourses
  } is sat
}

test suite for SatisfiesCaps {

  -- One student takes a course whose cap is 1
  example exactlyAtCap is SatisfiesCaps for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    `S1.courses = `C1 -> `True
    `C1.enrollmentCap = 1
    no `C1.prereqs
    no `Conc1.required_courses
  }

  -- Two students both take the same course in the same semester, but cap is 1
  example overCapacity is {not SatisfiesCaps} for {
    Student = `Stu1 + `Stu2
    CoursePlan = `Plan1 + `Plan2
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu2.plan = `Plan2
    `Stu1.concentration = `Conc1
    `Stu2.concentration = `Conc1
    `Plan1.first = `S1
    `Plan2.first = `S1
    no `S1.next

    `S1.courses = `C1 -> `True
    `C1.enrollmentCap = 1
    no `C1.prereqs
    no `Conc1.required_courses
  }

  -- Two students take the same course but in different semesters
  example sameCourseDifferentSemesters is SatisfiesCaps for {
    Student = `Stu1 + `Stu2
    CoursePlan = `Plan1 + `Plan2
    ConcentrationReqs = `Conc1
    Semester = `S1 + `S2
    Course = `C1
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu2.plan = `Plan2
    `Stu1.concentration = `Conc1
    `Stu2.concentration = `Conc1

    `Plan1.first = `S1
    no `S1.next
    `Plan2.first = `S2
    no `S2.next

    `S1.courses = `C1 -> `True
    `S2.courses = `C1 -> `True
    `C1.enrollmentCap = 1
    no `C1.prereqs
    no `Conc1.required_courses
  }

  -- A course not taken by anyone satisfies its cap.
  example unEnrolledCourse is SatisfiesCaps for {
    Student = `Stu1
    CoursePlan = `Plan1
    ConcentrationReqs = `Conc1
    Semester = `S1
    Course = `C1 + `C2
    Boolean = `True + `False
    True = `True
    False = `False

    `Stu1.plan = `Plan1
    `Stu1.concentration = `Conc1
    `Plan1.first = `S1
    no `S1.next

    `S1.courses = `C1 -> `True
    `C1.enrollmentCap = 5
    `C2.enrollmentCap = 1
    no `C1.prereqs
    no `C2.prereqs
    no `Conc1.required_courses
  }

  assert { SatisfiesCaps } is sat

  -- If SatisfiesCaps holds, the number of students in any course/semester
  -- pair never exceeds that course's cap
  assert {
    SatisfiesCaps
    some s: Semester, c: Course | {
      #{st: Student | semesterInPlan[st, s] and courseInSemester[s, c]}
        > c.enrollmentCap
    }
  } is unsat

  -- A course with enrollmentCap = 0 can never be taken by anyone
  assert {
    SatisfiesCaps
    some st: Student, s: Semester, c: Course | {
      c.enrollmentCap = 0
      semesterInPlan[st, s]
      courseInSemester[s, c]
    }
  } is unsat

  -- SatisfiesCaps is compatible with all other predicates
  assert {
    SatisfiesPrereqs
    SatisfiesConcentrationReqs
    SatisfiesCaps
    wellFormedPlan
    wellFormedCourses
    validCourseLoad
    noDuplicateCourses
  } is sat
}