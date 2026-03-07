module wirefollower() {

        module triangle2d(p, h) {
                polyhedron(
                points=[ [p[0][0], p[0][1],-h/2],[p[1][0],p[1][1],-h/2],[p[2][0],p[2][1],-h/2], 
                         [p[0][0], p[0][1],h/2],[p[1][0],p[1][1],h/2],[p[2][0],p[2][1],h/2] ],         // the apex point 
                faces=[ [0,1,2], [3,4,5], 
                        [0,1,4,3],
                        [0,2,5,3],
                        [1,2,5,4] ]                        // two triangles for square base
                );
        }


        module wire(p1, p2, w) {
                // Calculate the vector components
                v = p2 - p1;
                // Calculate the total Euclidean distance (length of the wire)
                d = sqrt(pow(v[0], 2) + pow(v[1], 2) + pow(v[2], 2));
               
                // Calculate the angles for rotation
                // atan2(y, x) gives the angle in the XY plane
                // acos(z/d) gives the angle from the Z axis
                angle_z = atan2(v[1], v[0]);
                angle_y = acos(v[2] / d);
               
                translate(p1)
                        rotate([0, angle_y, angle_z])
                        cylinder(h = d, r = w / 2, $fn = 24);
        }


        module camera() {
                cube([3.81, 1.4, 4.191], center=true);
        }


        module battery18650() {
                //https://www.optimusdigital.ro/en/battery-holders/942-1x18650-battery-case.html?search_query=18650&results=58
                cube([7.3,1.6,1.7]);
        }


        module wheel() {
                //https://www.robofun.ro/roti-si-senile/roti-42x19mm.html
                rotate([0,90,0])
                cylinder(h=1.9, r=2.1, $fn=24);
        }

        module motorHolder() {
        }


        module motor() {
                //https://sigmanortec.ro/Motor-DC-Micro-Metal-6V-HPCB-Perii-Carbon-30-1-p200733572


                rotate([0,0,90])
                union() {
                translate([0.5,0,0.6])
                rotate([90,0,0])
                        cylinder(h=0.97, r=0.29, $fn=10);
                cube([1,2.6,1.2]);
                }
        }


        module trapez(lw,uw,h,t) {


                Points = [
                [  0,  0,  -t/2 ],  //0
                [ lw,  0,  -t/2 ],  //1
                [ (lw-uw)/2 + uw,  h,  -t/2 ],  //2
                [ (lw-uw)/2,  h,  -t/2 ],  //3
                [  0,  0,  t/2 ],  //4
                [ lw,  0,  t/2 ],  //5
                [ (lw-uw)/2 + uw,  h,  t/2 ],  //6
                [ (lw-uw)/2,  h,  t/2 ]]; //7
               
                Faces = [
                [0,1,2,3],  // bottom
                [4,5,1,0],  // front
                [7,6,5,4],  // top
                [5,6,2,1],  // right
                [6,7,3,2],  // back
                [7,4,0,3]]; // left
 
                polyhedron(
                        points=Points,
                        faces=Faces,
                        convexity = 1);
        }

        module motorHolder(wall_thickness = 0.2, tolerance = 0.05) {
                // N20 Motor Base Dimensions (in cm)
                m_w = 1.0;  // Width
                m_l = 2.6;  // Length
                m_h = 1.2;  // Height
                
                // Outer Shell Dimensions
                // We add wall thickness to X and Z, and only one side of Y (leaving the back open)
                out_w = m_w + (2 * wall_thickness);
                out_l = m_l + wall_thickness;
                out_h = m_h + (2 * wall_thickness);
                
                rotate([0, 0, 90]) // Keeping your original chassis orientation
                difference() {
                        // 1. THE OUTER SHELL
                        // Translated so the inside corner of the motor sits perfectly at [0,0,0]
                        translate([-wall_thickness, 0, -wall_thickness-0.6])
                                cube([out_w, out_l, out_h + 0.6]);
                        
                        // 2. THE MOTOR CUTOUT (Negative Space)
                        // We add the 'tolerance' variable here to account for plastic shrinkage/over-extrusion
                        union() {
                                // Main body cutout
                                translate([-tolerance/2, -tolerance, -tolerance/2])
                                        cube([m_w + tolerance, m_l + tolerance * 2, m_h + tolerance]);
                                
                                // Shaft / Gearbox cutout (Front)
                                // Cylinder extends into the negative Y direction
                                translate([m_w / 2, 0.1, m_h / 2])
                                rotate([90, 0, 0])
                                        cylinder(h = 1.5, r = 0.3 + tolerance, $fn = 20); 
                        }
                        
                        // 3. THE TOP SNAP-IN SLOT (Weight saving & Assembly)
                        // This creates the opening at the top to slide the motor in.
                        // We make it slightly narrower than the motor to create a "snap" fit.
                        snap_width = m_w - 0.2; 
                        translate([(m_w - snap_width) / 2, -0.5, m_h / 2])
                                cube([snap_width, out_l + 1, out_h]); 
                }
        }

        module cameraHolder(wall_thickness = 0.2, tolerance = 0.05) {
                // Pixy2.1 Dimensions (in cm)
                c_w = 3.81;
                c_d = 1.524;
                c_h = 4.191;
                
                // Outer Dimensions
                out_w = c_w + (2 * wall_thickness) + tolerance;
                out_d = c_d + (2 * wall_thickness) + tolerance;
                out_h = c_h + wall_thickness;
                
                // Center the final part on the X and Y axes
                translate([-c_w/2, -c_d/2, 0])
                difference() {
                        // 1. MAIN BODY & MOUNTING WINGS
                        union() {
                                translate([-wall_thickness, -wall_thickness, -wall_thickness])
                                        cube([out_w, out_d, out_h]);
                        }
                        
                        // 2. THE CAMERA CAVITY
                        translate([-tolerance/2, -tolerance/2, 0])
                                cube([c_w + tolerance, c_d + tolerance, c_h + tolerance + 1]);
                                
                        // 3. FRONT U-CUTOUT (For the Lens)
                        // 1.2 cm from each side, starting 2.4 cm from the bottom
                        translate([1.2, -wall_thickness - 0.1, 2.4])
                                cube([c_w - 2.4, wall_thickness + 0.2, c_h]);
                                
                        // 4. THE BACK CUTOUT (Mirrored for the Pins)
                        // Cuts from the left edge (X=0) inwards. 
                        // Since the distance from the left edge to the covered part is 1.31 cm (3.81 - 2.5)
                        translate([-wall_thickness - 0.1, c_d - 0.1, -0.1])
                                cube([(c_w - 2.5) + wall_thickness + 0.1, wall_thickness + 0.2, c_h + 1]);
                        
                        // 5. MICRO-USB PORT (Left side, Z = 2.5 cm)
                        // 1.2 cm wide by 0.8 cm high cutout to clear the cable molding
                        translate([3.5+wall_thickness, c_d/2 - 0.6, 2.5 - 0.4])
                                cube([wall_thickness + 0.2, 1.2, 1.2]);
                                

                }
        }
       
       
        width = 20;
        w = 0.5;
        gndcl = 0.5;


        wire([-10,0,0],[10,0,0],w);
        wire([0,0,0],[0,20,0],w);


        translate([0,10,0])
        difference() {
                cylinder(h = 1, r = 10, center = true);
                cylinder(h = 2, r = 9, center = true);
                translate([-10,-25,-5])
                        cube([20,30,10]);
        }


        //translate([0,5/2,0])
        //cube([10,5,1], center = true);

        translate([-5,0,0])
                trapez(10,5,11,0.2);


        translate([8.5,-0.5,0.5])
        motor();

        translate([8.5,-0.5,0.5])
        motorHolder(wall_thickness = 0.2, tolerance = 0.03);


        // To test it, render the holder and drop the motor inside:
        rotate([0,0,180])
        translate([8,-0.5,0.5])
        motorHolder(wall_thickness = 0.2, tolerance = 0.03);

        rotate([0,0,180])
        translate([8,-0.5,0.5])
        motor();
       
        wire([0,10,0],[8.5,15,0],w);
        wire([0,10,0],[-8.5,15,0],w);
        wire([-5,0,0],[-2.5,11.5,0],w);
        wire([5,0,0],[2.5,11.5,0],w);
        
        wire([-5,0,0],[2.5,11.5,0],w);
        wire([5,0,0],[-2.5,11.5,0],w);

        //whell support
        wire([4,5,0],[9,0,0],w);
        wire([-4,5,0],[-9,0,0],w);

        //support
        wire([0,19,0],[5,13,0],w/2);
        wire([0,19,0],[-5,13,0],w/2);

        triangle2d([[0,10,0],[0,19,0],[5,13,0]], h=0.1);
        triangle2d([[0,10,0],[0,19,0],[-5,13,0]], h=0.1);

        rotate([0,90,0])
        triangle2d([[0,9,0],[0,6,0],[-5, 5,0]], h=0.1);


        //camera hold
        

        // Test render it
        translate([0,4,9 - 4.191/2])
        camera();
        
        // Render the camera holder
        rotate([0,0,180])
        translate([0,-4,5])
        cameraHolder(wall_thickness = 0.2, tolerance = 0.05);
        wire([0,9,0],[0,4,6],w);
        wire([4.6,2,0],[0,4,6],w);
        wire([-4.6,2,0],[0,4,6],w);


        // translate([5,2,-1])
        // rotate([90,0,103])
        // battery18650();


        // translate([-6.8,2,-1])
        // rotate([90,0,77])
        // battery18650();


        translate([10-0.8,0,2.1-(gndcl+w)])
        wheel();


        translate([-10-0.8,0,2.1-(gndcl+w)])
        wheel(); //0.65 ground clearance
       
}


translate([0,9,0]) // for animation
rotate([0,0,360*$t]) {
        translate([0,-9,0])
        wirefollower(); //camera nees to be 8.4cm off the ground
}


//Im making a car for a competition. Because my oponents have massive, complex cars (with bigger processors, suspension, and much more) <more than 500g i think> i decided to go the other way, by making my car as light and as simple as possible in order to obtain a 30s laptime on a 20m track. Do you think this is good? (i consider replacing the battery with 2s, im using N20 1000RPM motors that we will limit electronically, and consider good printing) 

