

local machine=require "statemachine"

local fsm=machine.create({
	initial="begin",
	events={
		{name="gamestart",from="begin",to="state2"},
		{name="allot",from="state2",to="state3"},
		{name="waitallot",from="state3",to="state4"},
		{name="waitplay",from="state4",to="state5"},
		{name="over",from="state5",to="begin"},
	},
	callbacks={
		ongamestart=function() print("gamestart")  end,
		onallot=function() print("allot") end,
		onwaitallot=function() print("waitallot") end,
		onwaitplay=function() print("waitplay") end,
		onover=function() print("over") end,
	}
})

fsm:gamestart()
fsm:allot()
fsm:waitallot()
fsm:waitplay()
fsm:over()
