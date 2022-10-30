module stacktrace_test
    use stacktrace_mod, only: stacktrace_t, stacktrace_error_hook_t
    use error_handling, only: error_t, set_error_hook, error_stop, fail
    use error_handling_experimental_result, only: result_integer_t
    implicit none

    private
    public test_stacktrace

contains


    subroutine test_stacktrace()
        write(*,*) 'test_stacktrace...'
        call procedures_should_not_fail
        call last_frame_should_contain_names
        call error_handling_integration
        call handler_should_work_with_experimental_result
        write(*,*) 'test_stacktrace [Ok]'
    end subroutine


    subroutine procedures_should_not_fail()
        type(stacktrace_t) :: st1
        character(len=:), allocatable :: chars

        call st1%load_here()
        chars = st1%to_chars(snippet=.false.)
        if (len(chars) == 0) call error_stop('Expected stacktrace in chars')
        block
            type(stacktrace_t) :: st2
            st2 = st1
            chars = st2%to_chars()
            if (len(chars) == 0) call error_stop('Expected stacktrace in chars')
        end block
        write(*, '(a)') st1%to_chars(snippet=.false.)
    end subroutine


    subroutine last_frame_should_contain_names()
        type(stacktrace_t) :: st1
        character(len=:), allocatable :: chars
        integer :: idx

        call st1%load_here()
        chars = st1%to_chars(snippet=.false.)
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
        class(error_t), allocatable :: error
        character(len=:), allocatable :: chars
        integer :: idx

        call set_error_hook(stacktrace_error_hook_t(snippet=.false.))
        error = fail('this failed')
        chars = error%to_chars()
        ! Start of last stack frame
        idx= index(chars, '#0')
        if (index(chars(idx:), 'error_handling_integration') < 1) then
            call error_stop('Expected procedure name in last frame of error stacktrace:' &
                    // new_line('c') // chars)
        end if
    end subroutine


    subroutine handler_should_work_with_experimental_result()
        type(result_integer_t) :: res

        call set_error_hook(stacktrace_error_hook_t(snippet=.false.))
        res = fortytwo_as_int('fortytwo')
        if (res%is_error()) call error_stop('Expected result')
        res = fortytwo_as_int('fortyone')
        if (.not. res%is_error()) call error_stop('Expected error')
        write(*,'(a,a)') 'Error: ', res%error%to_chars()
    end subroutine


    pure function fortytwo_as_int(chars) result(res)
        character(len=*), intent(in) :: chars
        type(result_integer_t) :: res

        if (chars == 'fortytwo') then
            res = 42
        else
            res = fail('Unknown')
        end if
    end function

end module