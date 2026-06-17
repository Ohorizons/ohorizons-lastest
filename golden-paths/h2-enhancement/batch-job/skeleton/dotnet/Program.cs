// ${{ values.jobName }} - Batch Job Entry Point

using System;
using System.IO;
using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace {{ values.jobName | replace("-", "_") | capitalize }};

public record CheckpointState(long Offset, string Status);

public static class Program
{
    private static readonly string CheckpointPath =
        Environment.GetEnvironmentVariable("CHECKPOINT_PATH")
        ?? Path.Combine(Path.GetTempPath(), "${{ values.jobName }}_checkpoint.json");

    private static ILogger _logger = null!;

    public static int Main(string[] args)
    {
        using var loggerFactory = LoggerFactory.Create(builder =>
            builder.AddConsole().SetMinimumLevel(LogLevel.Information));
        _logger = loggerFactory.CreateLogger("${{ values.jobName }}");

        try
        {
            var batchSize = 1000;
            if (args.Length > 0 && int.TryParse(args[0], out var bs))
                batchSize = bs;

            Run(batchSize);
            return 0;
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "Unhandled exception");
            return 1;
        }
    }

    private static CheckpointState LoadCheckpoint()
    {
        {% if values.enableCheckpointing %}
        if (File.Exists(CheckpointPath))
        {
            var json = File.ReadAllText(CheckpointPath);
            var state = JsonSerializer.Deserialize<CheckpointState>(json)!;
            _logger.LogInformation("Resumed from checkpoint: offset={Offset}", state.Offset);
            return state;
        }
        {% endif %}
        return new CheckpointState(0, "new");
    }

    private static void SaveCheckpoint(CheckpointState state)
    {
        {% if values.enableCheckpointing %}
        File.WriteAllText(CheckpointPath, JsonSerializer.Serialize(state));
        _logger.LogInformation("Checkpoint saved: offset={Offset}", state.Offset);
        {% endif %}
    }

    private static void ConnectSources()
    {
        {% for src in values.dataSources %}
        _logger.LogInformation("Connecting to data source: {{ src }}");
        {% endfor %}
    }

    private static void ConnectTargets()
    {
        {% for tgt in values.dataTargets %}
        _logger.LogInformation("Connecting to data target: {{ tgt }}");
        {% endfor %}
    }

    private static long ProcessBatch(long offset, int batchSize)
    {
        _logger.LogInformation("Processing batch at offset={Offset} size={Size}", offset, batchSize);
        // TODO: implement batch processing logic
        return offset + batchSize;
    }

    private static void Run(int batchSize)
    {
        var state = LoadCheckpoint();
        var offset = state.Offset;
        long totalProcessed = 0;

        ConnectSources();
        ConnectTargets();

        try
        {
            while (true)
            {
                var newOffset = ProcessBatch(offset, batchSize);
                if (newOffset == offset)
                {
                    _logger.LogInformation("No more records to process.");
                    break;
                }
                totalProcessed += newOffset - offset;
                offset = newOffset;
                SaveCheckpoint(new CheckpointState(offset, "running"));
            }
        }
        catch (Exception)
        {
            SaveCheckpoint(new CheckpointState(offset, "error"));
            throw;
        }

        SaveCheckpoint(new CheckpointState(offset, "completed"));
        _logger.LogInformation("Job complete. Total records processed: {Total}", totalProcessed);
    }
}
