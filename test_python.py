def hello_world():
    print("Hello, World!")
    return True

# This is correct Python syntax
class TestClass:
    def __init__(self):
        self.name = "Test"
    
    def display(self):
        print(f"Name: {self.name}")

# This will work
if __name__ == "__main__":
    obj = TestClass()
    obj.display()
