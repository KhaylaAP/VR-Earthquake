# VR Earthquake Simulator

![Status: Work in Progress](https://img.shields.io/badge/Status-Work_in_Progress-orange)
![Godot Engine](https://img.shields.io/badge/Godot-4.6.x-blue?logo=godotengine&logoColor=white)

An immersive, physics-driven Virtual Reality application designed for earthquake education and safety awareness. Built entirely in Godot 4, this project simulates a classroom environment where users can experience the unpredictable nature of seismic events through real-time physics interactions.

## 🌍 Overview

The goal of this project is to provide a highly realistic, interactive educational tool to demonstrate how environments react during an earthquake, making it a valuable asset for research and safety preparedness.

## ✨ Features

* **Fully Physical Environment:** Desks, chairs, and classroom objects are physics-enabled `RigidBody3D` nodes that react realistically to the moving floor.
* **Dynamic Structural Hazards:** Wall-mounted objects (like chalkboards) dynamically detach and fall when tremors reach a certain threshold.
* **Immersive VR Controls:** Full support for VR headsets and hand-tracking, allowing users to physically interact with and grab falling objects using Godot XR Tools.

## 🛠️ Built With

* [Godot Engine](https://godotengine.org/) - Version 4.6.1
* **GDScript** - For core logic and physics manipulation
* **Godot XR Tools** - For player movement and hand interactions

## 🚀 Getting Started

### Prerequisites
* Godot Engine v4.6.1 (or compatible Godot 4.x version)
* A compatible PC VR headset (Meta Quest via Link, Valve Index, HTC Vive, etc.)
* SteamVR or Oculus App installed and running
