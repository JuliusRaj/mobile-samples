using System;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;

namespace TaskAsyncProgrammingExample
{
    class Program
    {
        static async Task Main(string[] args)
        {
            Console.WriteLine("=== Task Asynchronous Programming Model Example ===\n");
            
            // Example 1: Old approach with ManualResetEvent (for comparison)
            Console.WriteLine("1. Old Multithreading Approach with ManualResetEvent:");
            await DemonstrateOldApproach();
            
            Console.WriteLine("\n" + new string('=', 60) + "\n");
            
            // Example 2: New TAP approach with proper task dependencies
            Console.WriteLine("2. New TAP Approach with Task Dependencies:");
            await DemonstrateTAPApproach();
            
            Console.WriteLine("\n" + new string('=', 60) + "\n");
            
            // Example 3: TAP with error handling and cancellation
            Console.WriteLine("3. TAP with Error Handling and Cancellation:");
            await DemonstrateTAPWithErrorHandling();
        }

        #region Old Multithreading Approach (ManualResetEvent)
        
        /// <summary>
        /// Demonstrates the old multithreading approach using ManualResetEvent
        /// This is what we're converting FROM
        /// </summary>
        static async Task DemonstrateOldApproach()
        {
            var stopwatch = Stopwatch.StartNew();
            
            // ManualResetEvents for synchronization
            var task1Complete = new ManualResetEventSlim(false);
            var task2Complete = new ManualResetEventSlim(false);
            var task3Complete = new ManualResetEventSlim(false);
            var task4Complete = new ManualResetEventSlim(false);
            
            // Task 1 - Independent
            var task1 = Task.Run(() =>
            {
                Console.WriteLine("  Task1 (Old): Starting independent work...");
                Thread.Sleep(1000); // Simulate work
                Console.WriteLine("  Task1 (Old): Completed");
                task1Complete.Set();
            });
            
            // Task 3 - Independent (runs in parallel with Task1)
            var task3 = Task.Run(() =>
            {
                Console.WriteLine("  Task3 (Old): Starting independent work...");
                Thread.Sleep(800); // Simulate work
                Console.WriteLine("  Task3 (Old): Completed");
                task3Complete.Set();
            });
            
            // Task 2 - Depends on Task1
            var task2 = Task.Run(() =>
            {
                Console.WriteLine("  Task2 (Old): Waiting for Task1...");
                task1Complete.Wait(); // Block until Task1 completes
                Console.WriteLine("  Task2 (Old): Starting work...");
                Thread.Sleep(600); // Simulate work
                Console.WriteLine("  Task2 (Old): Completed");
                task2Complete.Set();
            });
            
            // Task 4 - Depends on both Task2 and Task3
            var task4 = Task.Run(() =>
            {
                Console.WriteLine("  Task4 (Old): Waiting for Task2 and Task3...");
                Task.WaitAll(new[] { task2, task3 }); // Wait for both
                Console.WriteLine("  Task4 (Old): Starting work...");
                Thread.Sleep(500); // Simulate work
                Console.WriteLine("  Task4 (Old): Completed");
                task4Complete.Set();
            });
            
            // Task 5 - Depends on Task4
            var task5 = Task.Run(() =>
            {
                Console.WriteLine("  Task5 (Old): Waiting for Task4...");
                task4Complete.Wait(); // Block until Task4 completes
                Console.WriteLine("  Task5 (Old): Starting work...");
                Thread.Sleep(400); // Simulate work
                Console.WriteLine("  Task5 (Old): Completed");
            });
            
            // Wait for all tasks to complete
            await Task.WhenAll(task1, task2, task3, task4, task5);
            
            stopwatch.Stop();
            Console.WriteLine($"  Old approach completed in {stopwatch.ElapsedMilliseconds}ms");
            
            // Cleanup
            task1Complete.Dispose();
            task2Complete.Dispose();
            task3Complete.Dispose();
            task4Complete.Dispose();
        }
        
        #endregion

        #region New TAP Approach
        
        /// <summary>
        /// Demonstrates the new Task Asynchronous Programming Model (TAP)
        /// This is what we're converting TO
        /// </summary>
        static async Task DemonstrateTAPApproach()
        {
            var stopwatch = Stopwatch.StartNew();
            
            // Task 1 - Independent (starts immediately)
            var task1 = DoWorkAsync("Task1", 1000);
            
            // Task 3 - Independent (starts immediately, runs in parallel with Task1)
            var task3 = DoWorkAsync("Task3", 800);
            
            // Task 2 - Depends on Task1 completion
            var task2 = DoWorkWithDependencyAsync("Task2", 600, task1);
            
            // Task 4 - Depends on both Task2 and Task3 completion
            var task4 = DoWorkWithDependenciesAsync("Task4", 500, task2, task3);
            
            // Task 5 - Depends on Task4 completion
            var task5 = DoWorkWithDependencyAsync("Task5", 400, task4);
            
            // Wait for all tasks to complete
            await Task.WhenAll(task1, task2, task3, task4, task5);
            
            stopwatch.Stop();
            Console.WriteLine($"  TAP approach completed in {stopwatch.ElapsedMilliseconds}ms");
        }
        
        /// <summary>
        /// Simulates asynchronous work
        /// </summary>
        static async Task DoWorkAsync(string taskName, int delayMs)
        {
            Console.WriteLine($"  {taskName}: Starting work...");
            await Task.Delay(delayMs); // Non-blocking delay
            Console.WriteLine($"  {taskName}: Completed");
        }
        
        /// <summary>
        /// Simulates asynchronous work that depends on another task
        /// </summary>
        static async Task DoWorkWithDependencyAsync(string taskName, int delayMs, Task dependency)
        {
            Console.WriteLine($"  {taskName}: Waiting for dependency...");
            await dependency; // Wait for dependency to complete
            Console.WriteLine($"  {taskName}: Starting work...");
            await Task.Delay(delayMs);
            Console.WriteLine($"  {taskName}: Completed");
        }
        
        /// <summary>
        /// Simulates asynchronous work that depends on multiple tasks
        /// </summary>
        static async Task DoWorkWithDependenciesAsync(string taskName, int delayMs, Task dependency1, Task dependency2)
        {
            Console.WriteLine($"  {taskName}: Waiting for dependencies...");
            await Task.WhenAll(dependency1, dependency2); // Wait for both dependencies
            Console.WriteLine($"  {taskName}: Starting work...");
            await Task.Delay(delayMs);
            Console.WriteLine($"  {taskName}: Completed");
        }
        
        #endregion

        #region TAP with Error Handling and Cancellation
        
        /// <summary>
        /// Demonstrates TAP with proper error handling and cancellation support
        /// </summary>
        static async Task DemonstrateTAPWithErrorHandling()
        {
            var stopwatch = Stopwatch.StartNew();
            var cancellationTokenSource = new CancellationTokenSource();
            
            try
            {
                // Task 1 - Independent with cancellation support
                var task1 = DoWorkWithCancellationAsync("Task1", 1000, cancellationTokenSource.Token);
                
                // Task 3 - Independent with cancellation support
                var task3 = DoWorkWithCancellationAsync("Task3", 800, cancellationTokenSource.Token);
                
                // Task 2 - Depends on Task1 with error handling
                var task2 = DoWorkWithDependencyAndErrorHandlingAsync("Task2", 600, task1, cancellationTokenSource.Token);
                
                // Task 4 - Depends on both Task2 and Task3 with error handling
                var task4 = DoWorkWithDependenciesAndErrorHandlingAsync("Task4", 500, task2, task3, cancellationTokenSource.Token);
                
                // Task 5 - Depends on Task4 with error handling
                var task5 = DoWorkWithDependencyAndErrorHandlingAsync("Task5", 400, task4, cancellationTokenSource.Token);
                
                // Wait for all tasks to complete
                await Task.WhenAll(task1, task2, task3, task4, task5);
                
                stopwatch.Stop();
                Console.WriteLine($"  TAP with error handling completed in {stopwatch.ElapsedMilliseconds}ms");
            }
            catch (OperationCanceledException)
            {
                Console.WriteLine("  Operation was cancelled");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  Error occurred: {ex.Message}");
            }
            finally
            {
                cancellationTokenSource.Dispose();
            }
        }
        
        /// <summary>
        /// Simulates asynchronous work with cancellation support
        /// </summary>
        static async Task DoWorkWithCancellationAsync(string taskName, int delayMs, CancellationToken cancellationToken)
        {
            Console.WriteLine($"  {taskName}: Starting work...");
            
            try
            {
                await Task.Delay(delayMs, cancellationToken);
                Console.WriteLine($"  {taskName}: Completed");
            }
            catch (OperationCanceledException)
            {
                Console.WriteLine($"  {taskName}: Cancelled");
                throw;
            }
        }
        
        /// <summary>
        /// Simulates asynchronous work with dependency and error handling
        /// </summary>
        static async Task DoWorkWithDependencyAndErrorHandlingAsync(string taskName, int delayMs, Task dependency, CancellationToken cancellationToken)
        {
            try
            {
                Console.WriteLine($"  {taskName}: Waiting for dependency...");
                await dependency; // This will throw if dependency failed
                Console.WriteLine($"  {taskName}: Starting work...");
                await Task.Delay(delayMs, cancellationToken);
                Console.WriteLine($"  {taskName}: Completed");
            }
            catch (OperationCanceledException)
            {
                Console.WriteLine($"  {taskName}: Cancelled");
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  {taskName}: Failed due to dependency error: {ex.Message}");
                throw;
            }
        }
        
        /// <summary>
        /// Simulates asynchronous work with multiple dependencies and error handling
        /// </summary>
        static async Task DoWorkWithDependenciesAndErrorHandlingAsync(string taskName, int delayMs, Task dependency1, Task dependency2, CancellationToken cancellationToken)
        {
            try
            {
                Console.WriteLine($"  {taskName}: Waiting for dependencies...");
                await Task.WhenAll(dependency1, dependency2); // This will throw if any dependency failed
                Console.WriteLine($"  {taskName}: Starting work...");
                await Task.Delay(delayMs, cancellationToken);
                Console.WriteLine($"  {taskName}: Completed");
            }
            catch (OperationCanceledException)
            {
                Console.WriteLine($"  {taskName}: Cancelled");
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  {taskName}: Failed due to dependency error: {ex.Message}");
                throw;
            }
        }
        
        #endregion
    }
}