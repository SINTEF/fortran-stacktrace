! tag::usage[]
module sqrt_inplace_mod
    use error_handling, only: error_t
    implicit none

    private
    public sqrt_inplace

contains

    pure subroutine sqrt_inplace(x, error)
        real, intent(inout) :: x
        type(error_t), allocatable, intent(inout) :: error

        if (x <= 0.0) then
            error = error_t('x is negative')
            return
        end if
        x = sqrt(x)
    end subroutine

end module
! end::usage[]


module error_handling_integration_example
    implicit none

    private
    public run

contains

    subroutine run()
        use error_handling, only: error_t, set_error_hook
        use stacktrace_mod, only: stacktrace_error_hook_t
        use sqrt_inplace_mod, only: sqrt_inplace
        implicit none

        real :: x
        type(error_t), allocatable :: error

        ! Do this once near the start of your application to generate
        ! a stacktrace when errors are created. It is also possible to write
        ! your own custom error_hook_t and error_handler_t
        call set_error_hook(stacktrace_error_hook_t())

        ! Here we are using a labelled block to separate multiple fallible
        ! procedure calls from the code that handles any error
        fallible: block
            write(*,*) 'computing square root...'
            x = 20.0
            call sqrt_inplace(x, error)
            ! If an error occurred, go to error handling code
            if (allocated(error)) exit fallible
            ! Success -> write result
            write(*,*) ' - sqrt = ', x
            write(*,*) 'computing square root...'
            x = - 20.0
            call sqrt_inplace(x, error)
            if (allocated(error)) exit fallible
            write(*,*) ' - sqrt = ', x
            ! Return from subroutine on success, code below is only for
            ! error handling so no allocated(error) check is needed there.
            return
        end block fallible
        ! If we're here then an error has happened!
        write(*, '(a)')
        write(*, '(a)') error%display()
    end subroutine
end module

program error_handling_integration
    use error_handling_integration_example, only: run

    call run
end program

