--- 模块功能：testTask
-- @module test
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2017.02.17
function taskm(v1, v2)
    local count = 0
    log.info("taskm start", v1, v2)
    while true do
        log.info("taskm delay", count)
        sys.wait(60000)
        count = count + 1
        sys.publish("TEST_WAIT_UNTIL")
    end
end

function taskn(v1, v2)
    local count = 1
    log.info("taskn waitUntil is start ! ------------------------------")
    sys.waitUntil("TEST_WAIT_UNTIL", 6000000)
    while true do
        log.info("taskn delay", count)
        sys.wait(1000)
        count = count + 1
    end
end

sys.taskInit(taskm, "m", "c")
sys.taskInit(taskn, "n", "c")
