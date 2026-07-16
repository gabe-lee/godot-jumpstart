extends RefCounted

const MY_CONST = "HELLO"

var my_val = MY_CONST

func my_func() -> void:
    # BEGIN MY BODY
    my_val = 'it worked!'
    # END MY BODY
    print(my_val)

func something_else() -> void:
    pass
#EOF
