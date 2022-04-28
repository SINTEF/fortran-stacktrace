program generating_stacktrace
    use stacktrace_mod, only: stacktrace_t
    implicit none

    type(stacktrace_t) :: st
    character(len=:), allocatable :: chars

    ! Load a stacktrace from this point
    call st%load_here()

    ! Convert the stacktrace into character, e.g. for writing to console a log file.
    ! `snippet=.false.` disables snippet generation even when sources are available
    chars = st%display(snippet=.false.)
    write(*,'(a)') chars
end program