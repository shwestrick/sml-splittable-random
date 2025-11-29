import java.util.SplittableRandom;

public class JavaDump {

  

  public static void main(String[] args) {

    if (args.length != 2) {
      System.err.println("Usage: java JavaDump <count> <seed>");
      System.exit(1);
    }

    int count = 0;
    long seed = 0;

    try {
      count = Integer.parseInt(args[0]);
      seed = Long.parseLong(args[1]);
      if (count < 0) {
          System.err.println("Error: Count must be a non-negative integer.");
          System.exit(1);
      }
    } catch (NumberFormatException e) {
      System.err.println("Error: Both arguments must be valid integers.");
      System.exit(1);
    }

    SplittableRandom r = new SplittableRandom(seed);
    dump_at(r, count);

    SplittableRandom r_l = r;
    SplittableRandom r_r = r.split();
    dump_at(r_l, count);
    dump_at(r_r, count);

    SplittableRandom r_ll = r_l;
    SplittableRandom r_lr = r_l.split();
    dump_at(r_ll, count);
    dump_at(r_lr, count);

    SplittableRandom r_rl = r_r;
    SplittableRandom r_rr = r_r.split();
    dump_at(r_rl, count);
    dump_at(r_rr, count);
  }


  public static void dump_at(SplittableRandom r, int count) {
    for (int i = 0; i < count; i++) {
      System.out.println(r.nextLong());
    }

    for (int i = 0; i < count; i++) {
      System.out.println(r.nextInt());
    }

    for (int i = 0; i < count; i++) {
      System.out.printf("%.11f\n", r.nextDouble());
    }
  }

}