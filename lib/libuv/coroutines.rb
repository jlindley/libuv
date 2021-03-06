require 'fiber'

class ::Libuv::Loop
    @@use_fibers = true
end

class Object
    private


    # Takes a Promise response and turns it into a co-routine
    # for code execution without using callbacks
    #
    # @param *promises [::Libuv::Q::Promise] a number of promises that will be combined into a single promise
    # @return [Object] Returns the result of a single promise or an array of results if provided multiple promises
    # @raise [Exception] if the promise is rejected
    def co(*yieldable, &block)
        f = Fiber.current
        wasError = false

        # Convert the input into a promise
        if yieldable.length == 1
            promise = yieldable[0]
        else
            promise = ::Libuv::Loop.current.all(*yieldable)
        end

        # Use the promise to resume the Fiber
        promise.then(proc { |res|
            f.resume res
        }, proc { |err|
            wasError = true
            f.resume err
        })

        # Passed independently as this is often overwritten for performance
        promise.progress(block) if block_given?

        # Assign the result from the resume
        result = Fiber.yield

        # Either return the result or raise an error
        raise result if wasError
        result
    end
end
