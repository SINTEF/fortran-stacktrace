! SPDX-FileCopyrightText: 2022 SINTEF Ocean
! SPDX-License-Identifier: MIT

submodule(stacktrace_mod) hook_impl

contains


    pure module function create_handler(this, error) result(handler)
        class(stacktrace_error_hook_t), intent(in) :: this
        class(error_t), intent(in) :: error
        class(error_handler_t), allocatable :: handler

        type(stacktrace_error_handler_t), allocatable :: tmp

        allocate(tmp)
        allocate(tmp%stacktrace)
        call tmp%stacktrace%st%load_here(num_skip=4)
        tmp%snippet = this%snippet
        call move_alloc(tmp, handler)
        ! Avoid unused argument warning
        associate (dummy => error)
        end associate
    end function


    pure module function format_error(this, chain) result(chars)
        class(stacktrace_error_handler_t), intent(in) :: this
        type(error_chain_t), intent(in) :: chain
        character(len=:), allocatable :: chars

        chars = chain%error%to_chars()
        if (allocated(chain%cause)) then
            chars = chars // new_line('c') &
                // new_line('c') &
                // 'Caused by:' // new_line('c') &
                // chain_to_chars(chain%cause)
        end if

        if (allocated(this%stacktrace)) then
            chars = chars // new_line('c') // new_line('c') &
                // this%stacktrace%st%to_chars(snippet=this%snippet)
        end if
    end function


    pure recursive function chain_to_chars(chain) result(chars)
        type(error_chain_t), intent(in) :: chain
        character(len=:), allocatable :: chars

        chars = '  - ' // indent_newlines(chain%error%to_chars(), 4)
        if (.not. allocated(chain%cause)) then
            return
        end if
        chars = chars // new_line('c') &
            // chain_to_chars(chain%cause)
    end function


    recursive pure function indent_newlines(chars, n) result(indented)
        character(len=*), intent(in) :: chars
        integer, intent(in) :: n
        character(len=:), allocatable :: indented

        integer :: idx

        idx = index(chars, new_line('c'))
        if (idx <= 0) then
            indented = chars
        else
            indented = chars(1:idx)    &
                // repeat(' ', n) // indent_newlines(chars(idx + 1:), n)
        end if
    end function

end submodule