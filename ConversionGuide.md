# Converting from ManualResetEvent to Task Asynchronous Programming Model (TAP)

## Overview

This guide demonstrates how to convert C# code from the old multithreading approach using `ManualResetEvent` to the modern Task Asynchronous Programming Model (TAP) with `async`/`await`.

## Key Differences

### Old Approach (ManualResetEvent)
- **Blocking**: Uses `ManualResetEvent.Wait()` which blocks threads
- **Manual synchronization**: Requires explicit event management
- **Resource intensive**: Each blocked thread consumes memory
- **Error prone**: Easy to forget to dispose events or handle exceptions
- **Complex**: Requires careful coordination of multiple events

### New Approach (TAP)
- **Non-blocking**: Uses `await` which doesn't block threads
- **Automatic synchronization**: Task dependencies are handled automatically
- **Resource efficient**: No blocked threads, better scalability
- **Exception propagation**: Exceptions automatically propagate through the task chain
- **Simpler**: More readable and maintainable code

## Task Dependency Structure

The example implements this specific dependency structure:
```
Task1 (independent) ──┐
                     ├──→ Task4 ──→ Task5
Task3 (independent) ──┘
                     │
Task2 (depends on Task1) ──┘
```

## Step-by-Step Conversion Process

### 1. Replace ManualResetEvent with Task Dependencies

**Before (ManualResetEvent):**
```csharp
var task1Complete = new ManualResetEventSlim(false);
var task1 = Task.Run(() => {
    // work
    task1Complete.Set();
});
var task2 = Task.Run(() => {
    task1Complete.Wait(); // Blocking wait
    // work
});
```

**After (TAP):**
```csharp
var task1 = DoWorkAsync("Task1", 1000);
var task2 = DoWorkWithDependencyAsync("Task2", 600, task1);
```

### 2. Convert Synchronous Methods to Async

**Before:**
```csharp
void DoWork(string taskName, int delayMs)
{
    Thread.Sleep(delayMs); // Blocking
}
```

**After:**
```csharp
async Task DoWorkAsync(string taskName, int delayMs)
{
    await Task.Delay(delayMs); // Non-blocking
}
```

### 3. Handle Task Dependencies

**For single dependency:**
```csharp
async Task DoWorkWithDependencyAsync(string taskName, int delayMs, Task dependency)
{
    await dependency; // Wait for dependency
    await Task.Delay(delayMs);
}
```

**For multiple dependencies:**
```csharp
async Task DoWorkWithDependenciesAsync(string taskName, int delayMs, Task dep1, Task dep2)
{
    await Task.WhenAll(dep1, dep2); // Wait for all dependencies
    await Task.Delay(delayMs);
}
```

### 4. Add Error Handling

**With try-catch:**
```csharp
async Task DoWorkWithErrorHandlingAsync(string taskName, int delayMs, Task dependency)
{
    try
    {
        await dependency;
        await Task.Delay(delayMs);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Task {taskName} failed: {ex.Message}");
        throw; // Re-throw to propagate error
    }
}
```

### 5. Add Cancellation Support

**With CancellationToken:**
```csharp
async Task DoWorkWithCancellationAsync(string taskName, int delayMs, CancellationToken cancellationToken)
{
    await Task.Delay(delayMs, cancellationToken);
}
```

## Best Practices

1. **Always use `async Task` instead of `async void`** (except for event handlers)
2. **Propagate exceptions** by re-throwing them in catch blocks
3. **Use `Task.WhenAll()`** for parallel execution of independent tasks
4. **Use `Task.WhenAny()`** when you only need the first completed task
5. **Always dispose CancellationTokenSource** in finally blocks
6. **Use ConfigureAwait(false)** in library code to avoid deadlocks
7. **Prefer `Task.Run()` over `Task.Factory.StartNew()`** for simple scenarios

## Performance Benefits

- **Memory efficiency**: No blocked threads
- **Better scalability**: Can handle thousands of concurrent operations
- **Responsive UI**: Doesn't block the UI thread
- **Resource utilization**: Better CPU and I/O utilization

## Common Pitfalls to Avoid

1. **Don't use `Task.Wait()` or `Task.Result`** in async methods (causes deadlocks)
2. **Don't forget to await tasks** (results in fire-and-forget behavior)
3. **Don't catch exceptions without re-throwing** (unless you want to handle them)
4. **Don't use `Thread.Sleep()`** in async methods (use `Task.Delay()`)
5. **Don't forget to dispose resources** (use `using` statements or finally blocks)

## Migration Checklist

- [ ] Replace `ManualResetEvent` with `Task` dependencies
- [ ] Convert synchronous methods to `async Task`
- [ ] Replace `Thread.Sleep()` with `Task.Delay()`
- [ ] Replace blocking waits with `await`
- [ ] Add proper error handling
- [ ] Add cancellation support where needed
- [ ] Test the converted code thoroughly
- [ ] Update calling code to use `await`