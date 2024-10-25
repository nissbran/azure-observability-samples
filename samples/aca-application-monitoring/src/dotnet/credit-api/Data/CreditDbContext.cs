using CreditApi.Modules.Credit;
using Microsoft.EntityFrameworkCore;

namespace CreditApi.Data;

public class CreditDbContext(DbContextOptions<CreditDbContext> options) : DbContext(options) 
{
    public DbSet<Credit> Credits { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Credit>(builder =>
        {
            builder.HasKey(c => c.DbId);
            builder.Property(c => c.DbId).ValueGeneratedOnAdd().IsRequired();
            builder.Property(c => c.CreditId).IsRequired();
            builder.Property(c => c.Name).IsRequired();
            builder.Property(c => c.InterestRate).HasPrecision(18,2).IsRequired();
            builder.Property(c => c.CurrentMonth).IsRequired();
            builder.Ignore(c => c.NewTransactions);
            builder.HasMany(c => c.Transactions).WithOne().HasForeignKey("CreditDbId").OnDelete(DeleteBehavior.Cascade).IsRequired();
        });
        
        modelBuilder.Entity<Transaction>(builder =>
        {
            builder.HasKey(t => t.DbId);
            builder.Property(t => t.DbId).ValueGeneratedOnAdd().IsRequired();
            builder.Property(t => t.TransactionId).IsRequired();
            builder.Property(t => t.Value).IsRequired();
            builder.Property(t => t.TransactionDate).IsRequired();
        });
    }
}