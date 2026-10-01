extends DeckBlock

class_name OperatorReso

enum Operation {ADD, SUB, MUL, DIV}
const SYMBOLS := ["+", "-", "×", "÷"]

@export var operator : Operation
