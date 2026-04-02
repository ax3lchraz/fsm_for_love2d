machines = {}

machines.machines = {}

--[[

States are comprised of a required update function and optional enter and/or exit function. These functions are self-explanatory.
The update function may return a modality in order to update the machine internally.

Let a, b, ..., f denote state names and let u, v, ..., z denote modality names. Example:

local function update_b()

    return "u"

end

states = {
    a = {
        enter = function() ... end,
        update = function() ... end,
        exit = function() ... end
    },
    b = {
        update = update_b_func
    }
}

Modalities are the transitions between states. There are four types in this module:

Direct     | u = {from = "a", to = "b"}                           | Used for unique modality
Convergent | v = {from = {"a", "b", "c"}, to = "d"}               | Used for terminal modality, such as a reset state
Mapped     | w = {from = {"a", "b", "c"}, to = {"d", "e", "f"}}   | Used for a common modality, implemented to reduce repitition
Hybrid     | x = {from = {{"a", "b", "c"}, "d"}, to = {"e", "f"}} | Combines functionality of convergent and mapped

There cannot be duplicate modalities. Furthermore, for the mapped and hybrid types, the table lengths must be the same.

A simple coin flip betting game is constructed below. It just shows how connections need to be set up.
It's good practice to draw out your state machine beforehand for reference when setting up the modalities.

states = {
    betting = {enter = enable_betting_ui, update = get_bet_and_side, exit = disable_betting_ui},
    flipping = {enter = flip_coin, update = check_landed, exit = get_side}
    pay = {enter = pay_bet, update = function() return "continue" end},
    take = {enter = take_bet, update = function() return "continue" end}
}

modalities = {
    continue = {from = {"betting", {"pay", "take"}}, to = {"flipping", "betting"}},
    win = {from = "flipping", to = "pay"},
    loss = {from "flipping, to = "take"}
}

]]

local function convergent(machine, from)

    for i, v in ipairs(from) do
        if v == machine.current_state then
            return true
        end
    end

    return false
end

local function mapped(machine, from, to)

    for i, v in ipairs(from) do
        if type(v) == "table" then
            for _, u in ipairs(v) do
                if u == machine.current_state then return true, to[i] end
            end
        elseif type(v) == "string" then
            if v == machine.current_state then return true, to[i] end
        end
    end

    return false, nil
end

local function apply_modality(machine, modality)

    if not machine.modalities[modality] then return end

    local from, to = machine.modalities[modality].from, machine.modalities[modality].to
    local new_state
    local found = false

    if type(from) == "string" then

        if from == machine.current_state then new_state = to end

    elseif type(to) == "string" then

        if convergent(machine, from) then new_state = to end

    else

        found, new_state = mapped(machine, from, to)

    end

    if new_state then

        if machine.states[machine.current_state].exit then machine.states[machine.current_state].exit() end
        machine.current_state = new_state
        if machine.states[machine.current_state].enter then machine.states[machine.current_state].enter() end
        machine.states[machine.current_state].update()

    end

end

function machines.new(states, modalities, initial_state)

    assert(states, "States Required")
    assert(modalities, "Modalities Required")

    local machine = {
        states = states,
        modalities = modalities,
        initial_state = initial_state or "init",
        current_state = initial_state or "init",
        next_state = initial_state or "init"
    }

    if machine.states[machine.initial_state].enter then machine.states[machine.initial_state].enter() end

    function machine:update(modality)

        modality = modality or self.states[self.current_state].update()
        if modality then apply_modality(self, modality) end

    end

    function machine:reset()

        if self.states[self.current_state].exit then self.states[self.current_state].exit() end
        if self.states[self.initial_state].enter then self.states[self.initial_state].enter() end
        self.current_state = self.initial_state

    end

    table.insert(machines.machines, machine)

    return machine

end

function machines.update()

    for _, machine in ipairs(machines.machines) do machine:update() end

end

return machines
