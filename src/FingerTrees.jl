module FingerTrees
import Base: reduce, start, next, done, length, collect, split, eltype

export FingerTree, conjl, conjr, splitl, splitr, len, fingertree, flat, split, travstruct, traverse, concat
export EmptyFT

abstract FingerTree{T}
abstract Tree23{T}

immutable Leaf23{T} <: Tree23{T}
    a::T
    b::T
    c::Nullable{T}
    len::Int
    depth::Int
    function Leaf23(a, b) 
        if !(dep(a)==dep(b)) error("Try to construct uneven Leaf2") end
        new(a, b, Nullable{T}(), len(a)+len(b), dep(a)+1)
    end
    function Leaf23(a, b, c) 
        if !(dep(a)==dep(b)==dep(c)) error("Try to construct uneven Leaf3") end
        new(a,b,c, len(a)+len(b)+len(c), dep(a)+1)
    end
end

immutable Node23{T} <: Tree23{T}
    a::Tree23{T}
    b::Tree23{T}
    c::Nullable{Tree23{T}}
    len::Int
    depth::Int
    function Node23(a, b) 
        if !(dep(a)==dep(b)) error("Try to construct uneven Node2") end
        new(a, b, Nullable{Tree23}(), len(a)+len(b), dep(a)+1)
    end
    function Node23(a, b, c) 
        if !(dep(a)==dep(b)==dep(c)) error("Try to construct uneven Node3") end
        new(a,b,c, len(a)+len(b)+len(c), dep(a)+1)
    end
end


Tree23{T}(a::T,b::T,c::T) = Leaf23{T}(a,b,c)
Tree23{T}(a::T,b::T) = Leaf23{T}(a,b)
Tree23{T}(a::Tree23{T},b::Tree23{T},c::Tree23{T}) = Node23{T}(a,b,c)
Tree23{T}(a::Tree23{T},b::Tree23{T}) = Node23{T}(a,b)

astuple(n::Tree23) = isnull(n.c) ? (n.a, n.b) : (n.a, n.b, get(n.c))

abstract DigitFT{T,N}


immutable DLeaf{T,N} <: DigitFT{T,N}
    child::NTuple{N, T}
    len::Int
    depth::Int
    DLeaf() = new((),0,0)
    DLeaf(a) = new((a,), len(a), 0)
    function DLeaf(a::T,b::T) 
        new((a,b), len(a)+len(b), 0)
    end
    function DLeaf(a::T,b::T,c::T) 
        new((a,b,c), len(a)+len(b)+len(c), 0)
    end
    function DLeaf(a::T,b::T,c::T,d::T) 
        new((a,b,c,d), +(len(a),len(b),len(c),len(d)), 0)
    end    
end


immutable DNode{T,N} <: DigitFT{T,N}
    child::NTuple{N, Tree23{T}}
    len::Int
    depth::Int
    DNode() = new((),0,0)
    DNode(a) = new((a,), len(a), dep(a))
    function DNode(a,b) 
        if dep(a)!=dep(b) error("Try to construct uneven digit $b") end
        new((a,b), len(a)+len(b), dep(a))
    end
    function DNode(a,b,c) 
        if !(dep(a)==dep(b)==dep(c)) error("Try to construct uneven digit $b ") end
        new((a,b,c), len(a)+len(b)+len(c), dep(a))
    end
    function DNode(a,b,c,d) 
        if !(dep(a)==dep(b)==dep(c)==dep(d)) error("Try to construct uneven digit $b") end
        new((a,b,c,d), +(len(a),len(b),len(c),len(d)), dep(a))
    end    
end

typealias DigitFT0{T} DigitFT{T,0}
typealias DigitFT1{T} DigitFT{T,1}
typealias DigitFT2{T} DigitFT{T,2}
typealias DigitFT3{T} DigitFT{T,3}
typealias DigitFT4{T} DigitFT{T,4}

DigitFT{T}(a::T) = DLeaf{T,1}(a)  
DigitFT{T}(a::T,b::T) = DLeaf{T,2}(a,b)  
DigitFT{T}(a::T,b::T,c::T) = DLeaf{T,3}(a,b,c)  
DigitFT{T}(a::T,b::T,c::T,d::T) = DLeaf{T,4}(a,b,c,d)  
DigitFT{T}(a::Tree23{T}) = DNode{T,1}(a)  
DigitFT{T}(a::Tree23{T},b) = DNode{T,2}(a,b)  
DigitFT{T}(a::Tree23{T},b,c) = DNode{T,3}(a,b,c)  
DigitFT{T}(a::Tree23{T},b,c,d) = DNode{T,4}(a,b,c,d)  

function digit{T}(n::Tree23{T})
    if isnull(n.c) 
        DigitFT(n.a, n.b)
    else
        DigitFT(n.a, n.b, get(n.c))
    end
end    

immutable EmptyFT{T} <: FingerTree{T} 
end

immutable SingleFT{T} <: FingerTree{T} 
    a::Union(T, Tree23{T})
end
SingleFT{T}(a::T) = SingleFT{T}(a)
SingleFT{T}(a::Tree23{T}) = SingleFT{T}(a)


immutable DeepFT{T} <: FingerTree{T}
    left::DigitFT{T}
    succ::FingerTree{T}
    right::DigitFT{T}
    len::Int
    depth::Int
    function DeepFT(l::DigitFT{T}, s::FingerTree{T} , r::DigitFT{T})
        if !(dep(l) == dep(s) - 1 == dep(r) || (isempty(s) && dep(l) == dep(r)))
            dump(l); dump(s);dump(r)
            error("Attempt to construct uneven finger tree")
        end
        new(l, s, r, len(l) + len(s) + len(r), dep(l))
    end
    function DeepFT(ll, s::FingerTree{T} , rr)
        l = DigitFT(ll)
        r = DigitFT(rr)
        
        if !(dep(l) == dep(s) - 1 == dep(r) || (isempty(s) && dep(l) == dep(r)))
            dump(l); dump(s);dump(r)
            error("Attempt to construct uneven finger tree")
        end
        new(l, s, r, len(l) + len(s) + len(r), dep(l))
    end
end
DeepFT{T}(l::DigitFT{T}, s::FingerTree{T} , r::DigitFT{T}) = DeepFT{T}(l, s, r)
DeepFT{T}(l::Tree23{T}, s::FingerTree{T}, r::Tree23{T}) = DeepFT{T}(l, s, r)
DeepFT{T}(l::T, s::FingerTree{T}, r::T) = DeepFT{T}(l, s, r)
DeepFT{T}(l::T, r::T) = DeepFT{T}(DigitFT(l), EmptyFT{T}(), DigitFT(r))
DeepFT{T}(l::Tree23{T}, r::Tree23{T}) = DeepFT{T}(DigitFT(l), EmptyFT{T}(), DigitFT(r))
DeepFT{T}(l::DigitFT{T}, r::DigitFT{T}) = DeepFT{T}(l, EmptyFT{T}(), r)


# to safe (a lot of) compilation time, the depth of the tree is tracked and not guaranteed by a type constraint
dep(_) = 0
dep(n::Tree23) = n.depth
dep(d::DigitFT) = d.depth
dep(s::SingleFT) = dep(s.a)
dep(_::EmptyFT) = 0
dep(ft::DeepFT) = ft.depth



eltype{T}(b::FingerTree{T}) = T
eltype{T}(b::DigitFT{T}) = T


# TODO: allow other counting functions
len(a) = 1
len{N}(n::NTuple{N, Leaf23}) = N
len(_::()) = 0
len{N}(n::NTuple{N, Node23}) = mapreduce(len, +, n)::Int


len(n::Tree23) = n.len
len(digit::DigitFT) = digit.len
len(_::EmptyFT) = 0

len(deep::DeepFT) = deep.len
len(n::SingleFT) = len(n.a)
length(ft::FingerTree) = len(ft)

isempty(_::EmptyFT) = true
isempty(_::FingerTree) = false

width{T,N}(digit::DigitFT{T,N}) = N::Int
width(n::Tree23) = length(isnull(n.c) ? 3 : 2)

function conjl(t) 
    ft = t[end]
    for i in length(t)-1:-1:1
        ft = conjl(t[i], ft)
    end
    ft
end
function conjr(t) 
    ft = t[1]
    for x in t[2:end]
        ft = conjr(ft, x)
    end
    ft
end


FingerTree(K,ft::FingerTree) = ft
function FingerTree(K,t)
    ft = EmptyFT{K}()
    for x in t
        ft = conjr(ft, x)
    end
    ft
end

@inline fingertree(a) = SingleFT(a)
@inline fingertree(a,b) = DeepFT(a, b)
@inline fingertree(a,b,c) = DeepFT(DigitFT(a,b), DigitFT(c))
@inline fingertree(a,b,c,d) = DeepFT(DigitFT(a,b), DigitFT(c,d))
@inline fingertree(a,b,c,d,e) = DeepFT(DigitFT(a,b,c), DigitFT(d,e))
@inline fingertree(a,b,c,d,e,f) = DeepFT(DigitFT(a,b,c), DigitFT(d,e,f))
@inline fingertree(a,b,c,d,e,f,g) = DeepFT(DigitFT(a,b,c,d), DigitFT(e,f,g))
@inline fingertree(a,b,c,d,e,f,g,h) = DeepFT(DigitFT(a,b,c,d), DigitFT(e,f,g,h))


conjl{T}(a, digit::DigitFT0{T}) = DigitFT(a)
conjl{T}(a, digit::DigitFT1{T}) = DigitFT(a, digit.child[1])
conjl{T}(a, digit::DigitFT2{T}) = DigitFT(a, digit.child[1], digit.child[2])
conjl{T}(a, digit::DigitFT3{T}) = DigitFT(a, digit.child...)

conjr{T}(digit::DigitFT0{T}, a) = DigitFT(a)
conjr{T}(digit::DigitFT1{T}, a) = DigitFT(digit.child[1], a)
conjr{T}(digit::DigitFT2{T}, a) = DigitFT(digit.child[1], digit.child[2], a)
conjr{T}(digit::DigitFT3{T}, a) = DigitFT(digit.child..., a)


splitl{T}(digit::DLeaf{T,1}) = digit.child[1], DLeaf{T,0}()
splitl{T}(digit::DNode{T,1}) = digit.child[1], DNode{T,0}()
splitl{T}(digit::DigitFT2{T}) = digit.child[1], DigitFT(digit.child[2])
splitl{T}(digit::DigitFT3{T}) = digit.child[1], DigitFT(digit.child[2:end]...)
splitl{T}(digit::DigitFT4{T}) = digit.child[1], DigitFT(digit.child[2:end]...)

splitr{T}(digit::DLeaf{T,1}) = DLeaf{T,0}(), digit.child[end]
splitr{T}(digit::DNode{T,1}) = DNode{T,0}(), digit.child[end]
splitr{T}(digit::DigitFT2{T}) = DigitFT(digit.child[1]), digit.child[end]
splitr{T}(digit::DigitFT3{T}) = DigitFT(digit.child[1:end-1]...), digit.child[end]
splitr{T}(digit::DigitFT4{T}) = DigitFT(digit.child[1:end-1]...), digit.child[end]

function Base.getindex(d::DigitFT, i::Int)
    for k in 1:width(d)
        j = len(d.child[k]) 
        if i <= j return getindex(d.child[k], i) end
        i -= j    
    end
    throw(BoundsError())
end
function Base.getindex(n::Tree23, i::Int)
    j = len(n.a)
    i <= j && return getindex(n.a, i)
    i -= j; j = len(n.b)
    i <= j && return getindex(n.b, i)
    if !isnull(n.c)
        i -= j; j = len(get(n.c))
        i <= j && return getindex(get(n.c), i)
    end
    println(i, " ", j, n)
    throw(BoundsError())
end

Base.getindex(::EmptyFT, i) = throw(BoundsError())
Base.getindex(ft::SingleFT, i) = getindex(ft.a, i)
function Base.getindex(ft::DeepFT, i)
    j = len(ft.left)
    if i <= j return getindex(ft.left, i) end
    i -= j; j = len(ft.succ)
    if i <= j return getindex(ft.succ, i) end
    i -= j; j = len(ft.right)
    if i <= j return getindex(ft.right, i) end
    println(i, j, ft)
    throw(BoundsError())
end

conjl(a, _::EmptyFT) = SingleFT(a)
conjr(_::EmptyFT, a) = SingleFT(a)

conjl{K}(a, single::SingleFT{K}) = DeepFT(a,EmptyFT{K}(), single.a)
conjr{K}(single::SingleFT{K}, a) = DeepFT(single.a, EmptyFT{K}(),a)




function splitl(_::EmptyFT)
    error("finger tree empty")
end
splitr(l::EmptyFT) = splitl(l)

function splitl{K}(single::SingleFT{K})
    single.a, EmptyFT{K}()
end
function splitr{K}(single::SingleFT{K})
     EmptyFT{K}(), single.a
end
function conjl{T}(a, ft::DeepFT{T})
    if width(ft.left) < 4
        DeepFT(conjl(a,ft.left), ft.succ, ft.right)
    else
        f = Tree23(ft.left.child[2], ft.left.child[3], ft.left.child[4])
        DeepFT(DigitFT(a, ft.left.child[1]), conjl(f,ft.succ), ft.right)
    end
end

function conjr(ft::DeepFT, a)
    if width(ft.right) < 4
        DeepFT(ft.left, ft.succ, conjr(ft.right, a))
    else        
        f = Tree23(ft.right.child[1:3]...)
        DeepFT(ft.left, conjr(ft.succ, f), DigitFT(ft.right.child[4], a))
    end
end

function splitl(ft::DeepFT)
    a, as = splitl(ft.left)
    if width(as) > 0
        return a, DeepFT(as, ft.succ, ft.right)
    else
        if isempty(ft.succ) 
            b, bs = splitl(ft.right)
            if width(bs) > 0
                return a, DeepFT(DigitFT(b), ft.succ, bs)
            else
                return a, SingleFT(b)
            end
        else
            c, gt = splitl(ft.succ) 
            return a, DeepFT(digit(c), gt, ft.right)
        end
    end
end
function splitr(ft::DeepFT)
    as, a = splitr(ft.right)
    if width(as) > 0
        return DeepFT(ft.left, ft.succ, as), a
    else
        if isempty(ft.succ) 
            bs, b = splitr(ft.left)
            if width(bs) > 0
                return DeepFT(bs, ft.succ, DigitFT(b)), a
            else
                return SingleFT(b), a
            end
        else
             gt, c = splitr(ft.succ)
             return DeepFT(ft.left, gt, digit(c)), a
        end
    end
end

function split(ft::EmptyFT, i)
    error("can't split empty FingerTree")
end

function split{K}(ft::SingleFT{K}, i)
    if isa(ft.a, Tree23) return split(ft.a, i) end
    
    e = EmptyFT{K}() 
    return e, ft.a, e
end

function splitv(t, i)
    t[1:i-1], t[i], t[i+1:end]
end

function split(d::DigitFT, i)
    for k in 1:width(d)
        j = len(d.child[k]) 
        if i <= j 
            return splitv(d.child, k) end
        i -= j    
    end
    throw(BoundsError())
end
function split(n::Tree23, i)
    if isnull(n.c)
        j = len(n.a) 
        i <= j  && return (), n.a, (n.b,)
        i -= j; j = len(n.b) 
        i <= j  && return (n.a,), n.b, ()
    else 
        j = len(n.a) 
        i <= j  && return (), n.a, (n.b,get(n.c))
        i -= j; j = len(n.b) 
        i <= j  && return (n.a,), n.b, (get(n.c))
        i -= j; j = len(get(n.c)) 
        i <= j  && return (n.a,n.b), get(n.c), ()
    end
    throw(BoundsError())
end


function collect(xs::FingerTree)
     v = Array(eltype(xs), len(xs))
     traverse((x, i) -> (v[i] = x;), xs)
     v
end

rotr(d, ft::EmptyFT) = fingertree(d.child...)
function rotr{K}(d, ft::FingerTree{K})
    ft, x = splitr(ft)
    y = isa(x, Tree23) ? astuple(x) : (x,)
    if isa(ft, SingleFT) && !isa(ft.a, Tree23) return fingertree(d.child..., ft.a, y...) end
#    if isa(ft, SingleFT) return fingertree(d.child..., ft.a, y...) end
    DeepFT{K}(DigitFT(d.child...), ft, DigitFT(y...))
end
rotl(ft::EmptyFT, d) = fingertree(d.child...)
function rotl{K}(ft::FingerTree{K},d)
    x, ft = splitl(ft)
    y = isa(x, Tree23) ? astuple(x) : (x,) 
    if isa(ft, SingleFT) && !isa(ft.a, Tree23) return fingertree(y..., ft.a, d.child...) end
#    if isa(ft, SingleFT) return fingertree(y..., ft.a, d.child...) end
    DeepFT{K}(DigitFT(y...), ft, DigitFT(d.child...))
end

 
deepl(t::(), ft::FingerTree, d) = rotl(ft, d) 
deepl{K}(t::Tree23, ft::FingerTree{K}, d) = DeepFT{K}(DigitFT(t), ft, d)
deepl{K}(t, ft::FingerTree{K}, d) = DeepFT{K}(DigitFT(t...), ft, d)

deepr(d, ft::FingerTree, t::()) = rotr(d, ft) 
deepr{K}(d, ft::FingerTree{K}, t::Tree23) = DeepFT{K}(d, ft, DigitFT(t))
deepr{K}(d, ft::FingerTree{K}, t) = DeepFT{K}(d, ft, DigitFT(t...))

function split{K}(ft::DeepFT{K}, i)
    j = len(ft.left)
    if i <= j
        l, x, r = split(ft.left, i) 
        return FingerTree(K,l), x, deepl(r, ft.succ, ft.right)
    end
    i -= j; j = len(ft.succ)
    if i <= j 
        ml, xs, mr = split(ft.succ, i)    
        i -= len(ml)
        l, x, r =  isa(xs,Tree23) ? split(xs, i) : ((),xs,())
        ml = FingerTree(K,ml)
        mr = FingerTree(K,mr)
        return deepr(ft.left, ml, l), x, deepl(r, mr, ft.right)
    end
    i -= j; j = len(ft.right)
    if i <= j 
        l, x, r = split(ft.right, i) 
        return deepr(ft.left, ft.succ, l), x, FingerTree(K,r)
    end
    throw(BoundsError())
end


Base.reduce(op::Function, v, ::EmptyFT) = v
Base.reduce(op::Function, v, t::SingleFT) = reduce(op, v, ft.a)
function Base.reduce(op::Function, v, d::DigitFT)
    for k in 1:width(d)
        v = reduce(op, v, d.child[k])
    end
    v
end
function Base.reduce(op::Function, v, n::Tree23)
    t = tuple(n)
    for k in 1:width(t)
        v = reduce(op, v, t[k])
    end
    v
end
function Base.reduce(op::Function, v, ft::DeepFT)
    v = reduce(op, v, ft.left)
    v = reduce(op, v, ft.succ)
    v = reduce(op, v, ft.right)
end

traverse(op::Function, a, i) = (op(a, i); i + 1)
traverse(op::Function,  ::EmptyFT, i) = return i
traverse(op::Function, ft::SingleFT, i) = traverse(op, ft.a, i)

function traverse(op::Function, n::DigitFT, i)
    for k in 1:width(n)
        i = traverse(op, n.child[k], i)
    end
    i
end
function traverse(op::Function, n::Tree23, i)
    i = traverse(op, n.a, i)
    i = traverse(op, n.b, i)
    !isnull(n.c) && (i = traverse(op, get(n.c), i))
    i
end
function traverse(op::Function, ft::DeepFT, i)
    i = traverse(op, ft.left, i)
    i = traverse(op, ft.succ, i)
    traverse(op, ft.right, i)
end
traverse(op, ft) = (traverse(op, ft, 1);)


#Traversal with a op that takes also the depth as input
travstruct(op::Function, a, d) = (op(a, d);d)
travstruct(op::Function,  ::EmptyFT, d) = return d
travstruct(op::Function, ft::SingleFT, d) = travstruct(op, ft.a, d)
function travstruct{T}(op::Function,n::DigitFT{T}, d)
    d2 = travstruct(op, n.child[1], d)
    for k in 2:width(n)
        assert(d2 == travstruct(op, n.child[k], d ))
    end
    d2
end
function travstruct(op::Function, ft::DeepFT, d)
    d2 = travstruct(op, ft.left, d) 
    assert(d2 == travstruct(op, ft.succ, d + 1) - 1 ==  travstruct(op, ft.right, d))
    d2 
end
travstruct(op, ft) = travstruct(op, ft, 1)


# Scheme:
# state = start(I)
# while !done(I, state)
#   (i, state) = next(I, state)
#     # body
# end
# rather slow
function start(ft::FingerTree)
    trav = () -> traverse((x,i) -> produce(x), ft)
    t = Task(trav)
    i = consume(t)
    (i, t)
end
function next(ft::FingerTree, state)
    state[1], (consume(state[2]), state[2])
end
function done(ft::FingerTree, state)
    state[2].state==:done
end
 
 
app3(l::SingleFT, ts, r::SingleFT) = fingertree(l.a, ts..., r.a)
app3(::EmptyFT, ts, r::EmptyFT) =     fingertree(ts...) # for example ts::NTuple{N,Tree23}, 
app3(::EmptyFT, ts, r::SingleFT) = fingertree(ts..., r.a)
app3(l::SingleFT, ts, ::EmptyFT) = fingertree(l.a, ts...)
app3(::EmptyFT, ts, r) = conjl(tuple(ts..., r))
app3(l, ts, ::EmptyFT) = conjr(l, ts...)
app3(x::SingleFT, ts, r) = conjl(x.a, conjl(tuple(ts..., r)))
app3(l, ts, x::SingleFT) = conjr(conjr(tuple(l, ts...)), x.a)


nodes(a,b) = (Tree23(a, b),)
nodes(a,b,c) = (Tree23(a,b,c),)
nodes(a,b,c,d) = (Tree23(a, b), Tree23(c,d))
nodes(a,b,c,xs...) = tuple(Tree23(a,b,c), nodes(xs...)...)

app3(l::DeepFT, ts, r::DeepFT) = 
    DeepFT(l.left, app3(l.succ, nodes(l.right.child..., ts..., r.left.child...),r.succ),  r.right)
concat(l::FingerTree, r::FingerTree) = app3(l, (), r)
concat(l::FingerTree, x, r::FingerTree) = app3(l, (x,), r)


Base.show(io::IO, d::DigitFT) = print(io, d.child...)
Base.show(io::IO, n::Tree23) = len(n) < 20 ? print(io, "^", n.a, n.b, isnull(n.c) ? "" : get(n.c)) : print(" ... ")
Base.show(io::IO, d::DeepFT) = print(io, "(", d.left, " .. ", d.succ, " .. ", d.right, ")")
Base.show(io::IO, d::SingleFT) = print(io, "(", d.a, ")")
Base.show(io::IO, d::EmptyFT) = print(io, "(/)")


end
