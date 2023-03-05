# Join Channels

It is standard practice in nf-core to pass around a map with sample meta information as the first element in channels. It is therefore very tempting to use that map as the key to merge by in operators such as [join](https://www.nextflow.io/docs/latest/operator.html#join), [groupTuple](https://www.nextflow.io/docs/latest/operator.html#grouptuple), [combine](https://www.nextflow.io/docs/latest/operator.html#combine) (with `by`), or [cross](https://www.nextflow.io/docs/latest/operator.html#cross).

When such a map is also modified directly, this can break the merging operation when resuming a pipeline. (I'm not completely sure of the underlying reason.) This can be verified with the `failOnMismatch: true` option for `join`.

## Usage

1. First, change to the `data` directory, then run the `fetch_reads.sh` script. This may take a while depending on your internet connection.

    ```sh
    cd data
    ./fetch_reads.sh
    cd ..
    ```

2. Change to the directory demonstrating the problem where such a map is modified in place. After some samples have been processed successfully, you should interrupt the pipeline (`Ctrl + c`), then resume it by executing the script `run.sh` again

    ```sh
    cd problem
    ./run.sh
    cd ..
    ```

3. A potential solution to circumvent this problem is by creating a copy of the map when modifying it. As before, interrupt the pipeline, then resume it to convince yourself that this is a solution.

    ```sh
    cd solution_copy
    ./run.sh
    cd ..
    ```

4. Another solution is to pull out one or more simple keys, like integers or strings, from the map and merge on those. This requires more channel manipulations ([at least for now](https://github.com/nextflow-io/nextflow/issues/3108)) As before, interrupt the pipeline, then resume it to convince yourself that this is a solution.

    ```sh
    cd solution_keys
    ./run.sh
    cd ..
    ```

## Copyright

-   This is free and unencumbered software released into the public domain. See the [unlicense](UNLICENSE).
