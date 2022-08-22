using Prometheus;
using Serilog;
using Serilog.Exceptions;

var builder = WebApplication.CreateBuilder(args);

// Configure Elasticsearch Formatter for Production
if(!builder.Environment.IsDevelopment())
{
    builder.Host.UseSerilog((ctx, lc) => lc
    .Enrich.FromLogContext()
    .Enrich.WithExceptionDetails()
    .WriteTo.Console(formatter: new Serilog.Formatting.Elasticsearch.ElasticsearchJsonFormatter())
);
}

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();

app.UseAuthorization();
app.UseHttpMetrics();

app.MapControllers();
app.MapMetrics("/metrics");
app.MapHealthChecks("/health");

app.Run();
