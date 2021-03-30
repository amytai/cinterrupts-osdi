import java.io.*;

public class Cdf {
    public static void main(String[] args) throws IOException {
        double[] counts = new double[30];
        BufferedReader br = new BufferedReader(new FileReader(new File(args[0])));
	int lower = Integer.parseInt(args[1]);
        int bucket_size = Integer.parseInt(args[2]);
        double count = 0;
        int total = 0;
        while (br.ready()) {
            int line = Integer.parseInt(br.readLine().trim());
            int bucket = (line - lower) / bucket_size;
            if (bucket < 0) bucket = 0;
            if (bucket >= counts.length) bucket = counts.length - 1;
            counts[bucket]++;
            total++;
        }
        br.close();

        double sum = 0;
        for (int i = 0; i < counts.length; i++) {
            System.out.printf("%d %f\n", lower + i*bucket_size, sum/total);
            sum += counts[i];
        }
    }
}
