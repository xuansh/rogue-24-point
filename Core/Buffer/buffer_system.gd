extends Node

class_name BufferSystem

const MAX_SIZE := 4

var slots: Array = []

func init():
	slots.clear()

func add_number(num):
	if slots.size() >= MAX_SIZE:
		var pop_num = slots.pop_front()
	slots.push_back(num)
