import sys
import tkinter as tk

root = tk.Tk()
root.title("Boids Simulation")
canvas = tk.Canvas(root, width=640, height=480, bg="black")
canvas.pack()

boids = []
colors = ["white", "cyan", "magenta"]

def update():
    # Read up to 10 lines per frame to speed up rendering
    for _ in range(10):
        line = sys.stdin.readline()
        if not line:
            return
        
        try:
            parts = list(map(int, line.split()))
            if len(parts) % 2 != 0:
                continue
            
            num_boids = len(parts) // 2
            
            while len(boids) < num_boids:
                c = colors[len(boids) % 3]
                boids.append(canvas.create_oval(0, 0, 16, 16, fill=c))
                
            for i in range(num_boids):
                x = parts[i*2]
                y = parts[i*2+1]
                canvas.coords(boids[i], x, y, x+16, y+16)
        except ValueError:
            pass
            
    root.after(1000//30, update)

update()
root.mainloop()
