# # Using modern Hopfield networks for classification

using LogExpFunctions
using Plots
using LinearAlgebra, SparseArrays
using MLDatasets
using StatsBase

# Now, I'll create a data structure/composite type to store the components of the MCHN:

struct MCHN
    patterns
    simfun
    sepfun
    projmat
end

# And finally a function to actually do the probabilistic classification

function classify(mod::MCHN, ipt)
    #return mod.projmat * (ipt |> mod.simfun |> mod.sepfun)
    return mod.projmat * mod.sepfun(mod.simfun(mod.patterns, ipt))
end

# Now, to test the classifier on XOR

xorinputs = [1. 1; 1 0; 0 1; 0 0]
xoroutputs = [0.0, 1, 1, 0]
projmat = [1.0 0 0 1; 0 1 1 0]

mod0 = MCHN(xorinputs,
            (x, y) -> map(z -> count(y .== z), eachrow(x)),
            x -> softmax(10x),
            projmat)
classify(mod0, xorinputs[1, :])

# Now, we'll load the MNIST data store
training_data = MNIST(:train)
xtrain, ytrain = training_data[:]
xtrain = sparse(reshape(xtrain, 60_000, 28*28))

test_data = MNIST(:test)
xtest, ytest = test_data[:]
xtest = sparse(reshape(xtest, 10_000, 28*28))

alldata = vcat(xtrain, xtest)
alllabels = vcat(ytrain, ytest)

yproj = spzeros(10, size(alldata, 1))
for (i, n) in enumerate(alllabels)
    yproj[n+1, i] = 1
end

mnist_mod = MCHN(alldata, (x, y) -> x * y, x -> softmax(x), yproj)
mnist_mod2 = MCHN(alldata, (x, y) -> x * y, x -> softmax(2x), yproj)
res1 = classify(mnist_mod, alldata[1, :])#, alllabels[1]
kldivergence([0.0, 0, 0, 0, 0, 0, 1, 0, 0, 0], res1, 2)

# Testing
scores = zeros(size(alldata, 1))
Threads.@threads for i in eachindex(alllabels)
    corrvec = spzeros(10)
    corrvec[alllabels[i] + 1] = 1.0
    @inbounds scores[i] = kldivergence(corrvec, classify(mnist_mod, alldata[i, :]), 2)
end
res100 = classify(mnist_mod, alldata[1:100, :]')
res100b = classify(mnist_mod2, alldata[1:100, :]')

s1 = mapreduce(x -> crossentropy(x[1], x[2], 2), +, zip(eachcol(yproj[:, 1:100]), eachcol(res100)))
s2 = mapreduce(x -> crossentropy(x[1], x[2], 2), +, zip(eachcol(yproj[:, 1:100]), eachcol(res100b)))