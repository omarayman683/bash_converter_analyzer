public class SimpleTest {
    public static void helloWorld() {
        System.out.println("Hello, World!");
    }
    
    public static int addNumbers(int a, int b) {
        int result = a + b;
        System.out.println("The sum is: " + result);
        return result;
    }
    
    public static void main(String[] args) {
        helloWorld();
        addNumbers(5, 3);
    }
}
