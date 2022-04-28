module stacktrace_test
    use stacktrace_mod, only: stacktrace_t, stacktrace_error_hook_t
    use error_handling, only: error_t, set_error_hook, error_stop
    implicit none

    private
    public test_stacktrace

contains


    subroutine test_stacktrace()
        write(*,*) 'test_stacktrace...'
        call procedures_should_not_fail
        call last_frame_should_contain_names
        call error_handling_integration
        write(*,*) 'test_stacktrace [Ok]'
    end subroutine


    subroutine procedures_should_not_fail()
        type(stacktrace_t) :: st1
        character(len=:), allocatable :: chars

        call st1%load_here()
        chars = st1%display(snippet=.false.)
        if (len(chars) == 0) call error_stop('Expected stacktrace in chars')
        block
            type(stacktrace_t) :: st2
            st2 = st1
            chars = st2%display()
            if (len(chars) == 0) call error_stop('Expected stacktrace in chars')
        end block
        write(*, '(a)') st1%display(snippet=.false.)
    end subroutine


    subroutine last_frame_should_contain_names()
        type(stacktrace_t) :: st1
        character(len=:), allocatable :: chars
        integer :: idx

        call st1%load_here()
        chars = st1%display(snippet=.false.)
        if (chars /= '<Stacktrace not enabled for this build>') then
            ! Start of last stack frame
            idx= index(chars, '#0')
            if (index(chars(idx:), 'stacktrace_test.f90') < 1) then
                call error_stop('Expected filename in last frame of stacktrace:' &
                        // new_line('c') // chars)
            end if
            if (index(chars(idx:), 'stacktrace_test::') < 1) then
                call error_stop('Expected module name in last frame of stacktrace:' &
                        // new_line('c') // chars)
            end if
            ! Some compilers use the previous procedure name when procedures are inlined
            if (index(chars(idx:), 'last_frame_should_contain_names') < 1 &
                    .and. index(chars(idx:), 'stacktrace_test::test_stacktrace') < 1) then
                call error_stop('Expected procedure name in last frame of stacktrace:' &
                        // new_line('c') // chars)
            end if
        end if
    end subroutine


    subroutine error_handling_integration()
        type(error_t), allocatable :: error
        character(len=:), allocatable :: chars
        integer :: idx

        call set_error_hook(stacktrace_error_hook_t(snippet=.false.))
        error = error_t('this failed')
        chars = error%display()
        ! Start of last stack frame
        idx= index(chars, '#0')
        if (index(chars(idx:), 'error_handling_integration') < 1) then
            call error_stop('Expected procedure name in last frame of error stacktrace:' &
                    // new_line('c') // chars)
        end if
    end subroutine

end module