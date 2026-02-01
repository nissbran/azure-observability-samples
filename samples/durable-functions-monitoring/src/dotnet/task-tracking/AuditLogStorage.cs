using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace TaskTracking;

public class TaskAuditDbContext(DbContextOptions<TaskAuditDbContext> options) : DbContext(options)
{
    public DbSet<OrchestrationTask> Tasks => Set<OrchestrationTask>();
    public DbSet<OrchestrationAuditLog> AuditLogs => Set<OrchestrationAuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<OrchestrationTask>(entity =>
        {
            entity.ToTable("Tasks");
            entity.HasKey(task => task.InstanceId);
            entity.Property(task => task.InstanceId).HasMaxLength(200).IsRequired();
            entity.Property(task => task.Requester).HasMaxLength(200);
            entity.Property(task => task.CreatedAt).IsRequired();
            entity.Property(task => task.LastUpdatedAt).IsRequired();
            entity.HasMany(task => task.AuditLogs)
                  .WithOne(log => log.Task)
                  .HasForeignKey(log => log.InstanceId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OrchestrationAuditLog>(entity =>
        {
            entity.ToTable("TaskAuditLogs");
            entity.HasKey(log => log.Id);
            entity.Property(log => log.InstanceId).HasMaxLength(200).IsRequired();
            entity.Property(log => log.Status).HasMaxLength(100).IsRequired();
            entity.Property(log => log.Timestamp).IsRequired();
            entity.HasIndex(log => log.InstanceId);
        });
    }
}

public class OrchestrationTask
{
    public string InstanceId { get; set; } = string.Empty;
    public string? Requester { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset LastUpdatedAt { get; set; }
    public ICollection<OrchestrationAuditLog> AuditLogs { get; set; } = new List<OrchestrationAuditLog>();
}

public class OrchestrationAuditLog
{
    public long Id { get; set; }
    public string InstanceId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTimeOffset Timestamp { get; set; }
    public OrchestrationTask Task { get; set; } = null!;
}

public class AuditLogRequest
{
    public string InstanceId { get; init; } = string.Empty;
    public string? Requester { get; init; }
    public string Status { get; init; } = string.Empty;
    public DateTimeOffset Timestamp { get; init; }
}
