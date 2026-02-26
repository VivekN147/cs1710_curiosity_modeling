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