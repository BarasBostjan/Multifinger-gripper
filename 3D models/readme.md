# Printing guide

Here we outline the entire process of printing the gripper. The following sections detail the printers used, materials, and challenges encountered during the printing process.

## 3D Printers

To realize digital 3D models, we used the Ultimaker S5 printer, which uses 2.85 mm diameter materials and operates with FFF (Fused Filament Fabrication) technology. This printer supports a wide range of materials (PLA, ABS, nylon, PVA, support, etc.) and can print with two different materials simultaneously. As the gripper parts sometimes have complex shapes and many holes for screws and pins, it is optimal to print the parts from one material and the supports from another. This allows for high-quality complex shapes and easy removal of supports.

For parts requiring greater precision, we used the Stratasys Objet 24 printer. This printer uses a photopolymer material, which is applied in layers and then cured with ultraviolet light. Due to the high cost of these materials, this printer is used less frequently and for smaller, high-precision parts (such as gears).

## Materials Used

The most frequently used material was PLA (polylactic acid) because it is the easiest to print with, due to its low melting point and glass transition temperature. However, PLA is not resistant to temperatures above approximately 60°C, as it becomes rubbery above its glass transition temperature of 55°C to 65°C.

When higher temperature resistance was needed, we used ABS (Acrylonitrile Butadiene Styrene) plastic. The glass transition temperature of ABS is between 105°C and 115°C, making it solid under our application conditions. ABS is harder to print than PLA because it requires higher nozzle, bed, and chamber temperatures and often more support structures during printing.

We found that PLA plastic was more suitable for creating finger joints and mechanical guides, while ABS plastic was better suited for creating the frame. When joints and guides were printed from ABS, these parts often cracked during assembly, forcing us to reprint them. Even if a part didn’t crack during the initial creation, it might crack when we attempted to modify the finger later. We did not encounter these issues with PLA, so all mechanical guides and finger joints in the final version were made from this material. The frame needed to be made from ABS since the motors heat up during operation.

The most challenging is the printing of the worm gear. Initially, both the worm and the gear were printed from Vera White plastic. Early tests involving motor-driven movement of the robotic finger revealed that the gear cracked under minor torques. We then printed the gear from PLA plastic. Initially, we thought these gears would be much more durable than the previous ones. However, durability tests of the finger showed that the PLA gears wore out quickly during rapid, repetitive gripping and releasing actions.

Ultimately, we printed the gears from nylon. With nylon gears, we did not observe the wear that was present with Vera White and PLA plastics. However, when the gears were made from nylon, the worm began to disintegrate. We have not yet addressed this issue, but it serves as a good starting point for further development of the robotic finger.

The reconfiguration board, top plates, auxiliary part and auxiliary attachments were all printed using PLA plastic.

As a support material, we commonly used Ultimaker Breakaway, which is easy to print and remove but can be challenging if located in inaccessible areas of the object. When removal of supports was predicted to be too difficult, we used BVOH (Butene Diol Vinyl Alcohol), a water-soluble material, making post-processing easier by dissolving supports in water.

## Possible Printing Challenges

#### Fit and Finish
Printed elements do not fit together correctly immediately after printing. -> Account for printer tolerances in the 3D models.

#### Support Material Issues
Support materials do not adhere well to the bed, requiring multiple print starts. -> This can be partially mitigated by using a brim around the model to ensure better adhesion.

#### Orientation of Prints
Cracks appear around the drilled holes. -> The orientation of printed elements affected their strength, particularly for ABS and PLA. Avoid drilling holes in the direction of the layers due to the weaker bonds between layers.
