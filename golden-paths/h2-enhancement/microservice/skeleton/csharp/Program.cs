using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var startTime = DateTime.UtcNow;
var items = new ConcurrentDictionary<string, Item>();

// Health endpoints
app.MapGet("/health", () => new { status = "healthy", service = "${{ values.serviceName }}" });

app.MapGet("/ready", () => new
{
    status = "ready",
    uptime_seconds = (int)(DateTime.UtcNow - startTime).TotalSeconds
});

app.MapGet("/metrics", () => new
{
    service = "${{ values.serviceName }}",
    uptime_seconds = (int)(DateTime.UtcNow - startTime).TotalSeconds,
    items_count = items.Count
});

// CRUD endpoints
app.MapGet("/api/items", () => items.Values.ToList());

app.MapGet("/api/items/{id}", (string id) =>
    items.TryGetValue(id, out var item)
        ? Results.Ok(item)
        : Results.NotFound(new { error = "Item not found" }));

app.MapPost("/api/items", (ItemRequest req) =>
{
    var item = new Item(Guid.NewGuid().ToString(), req.Name, req.Description);
    items[item.Id] = item;
    return Results.Created($"/api/items/{item.Id}", item);
});

app.MapPut("/api/items/{id}", (string id, ItemRequest req) =>
{
    if (!items.TryGetValue(id, out var existing))
        return Results.NotFound(new { error = "Item not found" });

    var updated = existing with
    {
        Name = req.Name ?? existing.Name,
        Description = req.Description ?? existing.Description
    };
    items[id] = updated;
    return Results.Ok(updated);
});

app.MapDelete("/api/items/{id}", (string id) =>
{
    if (!items.TryRemove(id, out _))
        return Results.NotFound(new { error = "Item not found" });
    return Results.NoContent();
});

var port = Environment.GetEnvironmentVariable("PORT") ?? "${{ values.httpPort }}";
app.Urls.Add($"http://0.0.0.0:{port}");
app.Run();

record Item(string Id, string Name, string? Description);
record ItemRequest(string? Name, string? Description);
