    def Number(num)      ->(env){ num } end
    def Variable(var)    ->(env){ env[var] } end
    def Add(*args)       ->(env){ (n=args.pop) ? n.(env)+Add(*args).(env) : Number(0).(env) } end
    def Multiply(*args)  ->(env){ (n=args.pop) ? n.(env)*Multiply(*args).(env) : Number(1).(env) } end
    def Divide(num,dem)  ->(env){ num.(env) / dem.(env) } end

    ExpressionTree = Add(Variable(:a), Variable(:c), Multiply(Number(2), Variable(:b), Number(6), Divide(Number(4), Variable(:d))))
    Env = { a: 3, b: 4, c: 5, d: 2 }

    p ExpressionTree.(Env)
