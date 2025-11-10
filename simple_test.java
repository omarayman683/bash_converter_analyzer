public class simple_test {
    public static void hello_world() {
        System.out.println("Hello World!"  );
    }
    public static int add_numbers(int a,int b) {
        int result = a + b;
        System.out.println("The sum is:" + "result");
        return result;
    }

    public static void main(String[] args) {
        hello_world();
        add_numbers(5, 3);
}
}
