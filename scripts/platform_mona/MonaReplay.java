import de.fau.pi1.timerReporter.dataset.Dataset;
import de.fau.pi1.timerReporter.dataset.Secret;
import de.fau.pi1.timerReporter.dataset.Time;
import de.fau.pi1.timerReporter.evaluation.BoxTestResults;
import de.fau.pi1.timerReporter.evaluation.StatisticEvaluation;
import de.fau.pi1.timerReporter.plots.PlotPool;
import de.fau.pi1.timerReporter.reader.Reader;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.Locale;

public final class MonaReplay {
    private static final String UPSTREAM_COMMIT = "4c74fb7e629b4d057b2d5d4accdb120d920774b7";

    private static final class InputReader extends Reader {
        private final Path input_path;
        private String first_class;
        private String second_class;

        InputReader(Path input_path) {
            this.input_path = input_path;
        }

        private long parse_nanoseconds(String field) {
            if (!field.matches("[0-9]+")) {
                throw new IllegalArgumentException("Times must be nonnegative integer ns.");
            }
            return Long.parseLong(field);
        }

        @Override
        public void read(ArrayList<Secret> secrets) {
            Secret first_secret = new Secret("X", "class0");
            Secret second_secret = new Secret("Y", "class1");
            try (BufferedReader input_reader = Files.newBufferedReader(
                    input_path, StandardCharsets.UTF_8)) {
                String header = input_reader.readLine();
                if (header == null) {
                    throw new IllegalArgumentException("Missing input header.");
                }
                String[] header_fields = header.split(",", -1);
                if (header_fields.length != 2) {
                    throw new IllegalArgumentException("Require exactly two input columns.");
                }
                boolean is_normalized = header.equals("V1,V2");
                first_class = is_normalized ? "X" : header_fields[0];
                second_class = is_normalized ? "Y" : header_fields[1];
                if (!first_class.matches("[A-Za-z0-9_-]+")
                        || !second_class.matches("[A-Za-z0-9_-]+")
                        || first_class.equals(second_class)) {
                    throw new IllegalArgumentException("Invalid class names.");
                }
                String input_line;
                int input_index = 0;
                while ((input_line = input_reader.readLine()) != null) {
                    String[] fields = input_line.split(",", -1);
                    if (fields.length != 2) {
                        throw new IllegalArgumentException("Malformed CSV row.");
                    }
                    if (is_normalized) {
                        Secret selected_secret;
                        if (fields[0].equals("X")) {
                            selected_secret = first_secret;
                        } else if (fields[0].equals("Y")) {
                            selected_secret = second_secret;
                        } else {
                            throw new IllegalArgumentException("Normalized labels must be X/Y.");
                        }
                        selected_secret.addTime(new Time(input_index,
                                selected_secret.getTimes().size(), parse_nanoseconds(fields[1])));
                    } else {
                        first_secret.addTime(new Time(input_index * 2,
                                first_secret.getTimes().size(), parse_nanoseconds(fields[0])));
                        second_secret.addTime(new Time(input_index * 2 + 1,
                                second_secret.getTimes().size(), parse_nanoseconds(fields[1])));
                    }
                    input_index = Math.incrementExact(input_index);
                }
            } catch (IOException input_error) {
                throw new IllegalArgumentException("Cannot read input CSV.", input_error);
            }
            if (first_secret.getTimes().size() < 100 || second_secret.getTimes().size() < 100) {
                throw new IllegalArgumentException("Require at least 100 values per class.");
            }
            first_secret.sortTimes();
            second_secret.sortTimes();
            secrets.add(first_secret);
            secrets.add(second_secret);
        }

        @Override
        public String getInputFile() {
            return input_path.toString();
        }
    }

    private static final class NoPlotPool extends PlotPool {
        NoPlotPool(String output_directory, Dataset dataset) {
            super(output_directory, dataset);
        }

        @Override
        public void plot(String name, double lower_bound, double upper_bound) {
            // 只抑制排版回调；统计类和箱体搜索保持上游原样。
        }
    }

    private static void write_new(Path output_path, String content) throws IOException {
        Files.write(output_path, content.getBytes(StandardCharsets.UTF_8),
                StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
    }

    public static void main(String[] arguments) throws IOException {
        if (arguments.length != 2) {
            throw new IllegalArgumentException("usage: MonaReplay INPUT_CSV OUTPUT_DIRECTORY");
        }
        Path input_path = Paths.get(arguments[0]);
        Path output_directory = Paths.get(arguments[1]);
        InputReader input_reader = new InputReader(input_path);
        Dataset dataset = new Dataset(input_reader);
        NoPlotPool plot_pool = new NoPlotPool(output_directory.resolve("render-disabled").toString(),
                dataset);
        StatisticEvaluation evaluation = new StatisticEvaluation(dataset, plot_pool);
        try {
            evaluation.calibrationPhase();
            evaluation.printBoxTestResults(output_directory.resolve("box-results.csv").toFile());
        } finally {
            plot_pool.close();
        }
        int validated_records = 0;
        int rejected_records = 0;
        int single_subset_validated_records = 0;
        StringBuilder validation_rows = new StringBuilder(
                "direction,lower_percentile,upper_percentile,subset_size,subset_count,success_percentage\n");
        for (BoxTestResults box_result : evaluation.getBoxTestResults()) {
            for (int record_index = 0; record_index < box_result.getConfidenceInterval().size();
                    record_index++) {
                Double validation_percentage = box_result.getConfidenceInterval().get(record_index);
                int subset_count = box_result.getSignificantDifferent().get(record_index).size();
                if (validation_percentage.doubleValue() == 100.0) {
                    validated_records++;
                    if (subset_count == 1) {
                        single_subset_validated_records++;
                    }
                } else {
                    rejected_records++;
                }
                validation_rows.append(box_result.getSecretA().getName()).append("<")
                        .append(box_result.getSecretB().getName()).append(",")
                        .append(box_result.getOptimalBox()[0]).append(",")
                        .append(box_result.getOptimalBox()[1]).append(",")
                        .append(box_result.getSmallestSize().get(record_index)).append(",")
                        .append(subset_count).append(",").append(validation_percentage).append("\n");
            }
        }
        String status = validated_records > 0 ? "validated_box_separation" : "no_validated_box_separation";
        int first_count = dataset.getSecrets().get(0).getTimes().size();
        int second_count = dataset.getSecrets().get(1).getTimes().size();
        String summary_json = String.format(Locale.ROOT,
                "{\n  \"tool\": \"mona_upstream_offline\",\n"
                + "  \"upstream_commit\": \"%s\",\n  \"status\": \"%s\",\n"
                + "  \"class0_name\": \"%s\",\n  \"class1_name\": \"%s\",\n"
                + "  \"class0_count\": %d,\n  \"class1_count\": %d,\n"
                + "  \"validated_records\": %d,\n  \"rejected_records\": %d,\n"
                + "  \"single_subset_validated_records\": %d,\n"
                + "  \"trimming\": false,\n  \"holm_member\": false,\n"
                + "  \"p_value\": null,\n  \"alpha\": null\n}\n",
                UPSTREAM_COMMIT, status, input_reader.first_class, input_reader.second_class,
                first_count, second_count, validated_records, rejected_records,
                single_subset_validated_records);
        write_new(output_directory.resolve("mona.json"), summary_json);
        write_new(output_directory.resolve("mona-validations.csv"), validation_rows.toString());
        write_new(output_directory.resolve("mona.csv"),
                "tool,status,class0_count,class1_count,validated_records,rejected_records,holm_member\n"
                + "mona_upstream_offline," + status + "," + first_count + "," + second_count + ","
                + validated_records + "," + rejected_records + ",false\n");
        write_new(output_directory.resolve("mona.md"),
                "| Tool | Status | Class 0 | Class 1 | Validated records | Holm |\n"
                + "|---|---|---:|---:|---:|---|\n| Mona upstream offline | " + status + " | "
                + first_count + " | " + second_count + " | " + validated_records + " | no |\n\n"
                + "Upstream confidence field is a batch success percentage, not a p-value or coverage CI.\n"
                + "Validated records with only one subset: " + single_subset_validated_records + ".\n"
                + "No trimming; no separation does not prove constant time.\n");
        System.out.println("battery_mona_status=" + status);
    }
}
