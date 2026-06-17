var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors();

var app = builder.Build();
app.UseCors(p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
app.MapGet("/api/items", () => Results.Ok(new { items = Array.Empty<object>() }));

app.Run();
