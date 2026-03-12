function get_node(p1, p2, p3, p4) = 
    let (
        x1 = p1[0], y1 = p1[1],
        x2 = p2[0], y2 = p2[1],
        x3 = p3[0], y3 = p3[1],
        x4 = p4[0], y4 = p4[1],
        den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    )
    den == 0 ? [undef, undef, 0] : // Returns undefined if lines are parallel
    [
        ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4)) / den,
        ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4)) / den,
        (p1[2] + p2[2] + p3[2] + p4[2]) / 4 // Averages the Z-height just in case
    ];

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

        module sleeve_hub(center_pos, target_points, rod_dia = 0.5, sleeve_length = 1.0, wall_thickness = 0.15) {
                // Tolerances and Hardware
                r_inner = (rod_dia + 0.04) / 2;     // 5.4mm hole for a 5.0mm rod 
                r_outer = r_inner + wall_thickness; // 8.4mm outer diameter
                
                // M3 tap hole (1.8mm diameter to allow threads to bite)
                m2_tap_r = 0.125; // its actuall m3 
                
                // Safety buffer to prevent physical rods from colliding inside the hub
                insertion_offset = r_outer * 0.75;  
                
                translate(center_pos) {
                        difference() {
                        // 1. ADDITIVE: The solid core and outer sleeves
                        union() {
                                // Central binding sphere (acts as the solid core)
                                sphere(r = r_outer, $fn = 6);
                                
                                for (p = target_points) {
                                v = p - center_pos;      
                                d = norm(v);             
                                angle_z = atan2(v[1], v[0]); 
                                angle_y = acos(v[2] / d);
                                
                                rotate([0, angle_y, angle_z])
                                rotate([0,0,30])
                                        cylinder(h = sleeve_length, r = r_outer, $fn = 6);
                                }
                        }
                        
                        // 2. SUBTRACTIVE: Carve out channels and M2 holes
                        for (p = target_points) {
                                v = p - center_pos;
                                d = norm(v);
                                angle_z = atan2(v[1], v[0]);
                                angle_y = acos(v[2] / d);
                                
                                rotate([0, angle_y, angle_z]) {
                                // Carve the rod channel, starting at the offset so rods don't touch
                                translate([0, 0, insertion_offset])
                                rotate([0,0,30]) 
                                        cylinder(h = sleeve_length + 0.1, r = r_inner, $fn = 6);
                                        
                                // Carve the perpendicular M2 grub screw hole
                                // Positioned halfway along the available insertion depth
                                translate([0, 0, insertion_offset + ((sleeve_length - insertion_offset) / 2)])
                                        rotate([0, 90, 0])
                                        cylinder(h = r_outer * 3, r = m2_tap_r, center = true, $fn = 20);
                                }
                        }
                
                        difference() {
                                sphere(r = 2, $fn=32);
                                sphere(r = 1.0, $fn=32);
                        }
                        }
                }
        }

        module side_clasp(rod_dia = 0.5, plate_t = 0.2, sleeve_l = 1.2, wall = 0.2) {
            // Math & Hardware (cm)
            r_in = (rod_dia + 0.04) / 2; 
            r_out = r_in + wall;
            gap = plate_t + 0.05; // Clearance for the baseplate
            jaw_w = 0.8;          // Width of the clasping plates
            jaw_reach = 0.7;      // How far the plates reach onto the chassis
            m2_clear_r = 0.16;    // Top hole (slight clearance) // actually m3
            m2_tap_r = 0.125;     // Bottom hole (tight for threads) // actually m3
        
            union() {
                difference() {
                    // 1. THE MAIN BODY (Sleeve + Neck + Jaws)
                    union() {
                        // The Rod Sleeve
                        rotate([90, 0, 0])
                        rotate([0,0,30])
                        cylinder(h = sleeve_l, r = r_out, center = true, $fn = 6);
                        
                        // The "Neck" and Jaws
                        // Extends from the side of the sleeve over to the plate
                        translate([r_out - 0.25, -jaw_w/2, -(gap/2 + wall)])
                        cube([jaw_reach + 0.2, jaw_w, gap + (wall * 2)]);
                    }
        
                    // 2. SUBTRACTIVE: Carving the channels
                    // The Rod Hole
                    rotate([90, 0, 0])
                    rotate([0,0,30])
                    cylinder(h = sleeve_l + 0.1, r = r_in, center = true, $fn = 6);
        
                    // The Plate Gap (The "Mouth")
                    translate([r_out, -jaw_w - 0.1, -gap/2])
                    cube([jaw_reach + 0.2, (jaw_w * 2) + 0.2, gap]);
        
                    // M2 Bolt Holes (Vertical)
                    // Positioned in the center of the reach
                    bolt_x = r_out + (jaw_reach / 2);
                    
                    // Top Hole (Clearance)
                    translate([bolt_x, 0, gap/2 - 0.05])
                    cylinder(h = wall + 0.2, r = m2_clear_r, $fn = 16);
                    
                    // Bottom Hole (Tap)
                    translate([bolt_x, 0, -(gap/2 + wall + 0.1)])
                    cylinder(h = wall + 0.2, r = m2_tap_r, $fn = 16);
                }
            }
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
                rotate([0, 0, 30])
                cylinder(h = d, r = w / 2, $fn = 6);
        }


        module camera() {
                cube([3.81, 1.4, 4.191], center=true);
        }


        module battery() {
                //https://www.emag.ro/acumulator-lipo-2s-650mah-7-6v-95c-tattu-74x17x13mm-33g-kxg0118196/pd/DTKLKGYBM/
                cube([7.4,1.7,1.3]);
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

       module motorHolder(gndcl = 0.5, wall_thickness = 0.2, tolerance = 0.05) {
            // N20 Motor Base Dimensions (in cm)
            m_w = 1.0; 
            m_l = 2.6; 
            m_h = 1.2; 
            
            // Shaft center is in the middle of the height (0.6cm from motor bottom)
            shaft_offset_z = m_h / 2; 
        
            // Total height calculation: 
            // We need enough plastic under the motor to match the gndcl requirement
            // plus the motor itself and the top wall.
            out_w = m_w + (2 * wall_thickness);
            out_l = m_l + wall_thickness;
            out_h = m_h + (2 * wall_thickness) + gndcl;
        
            rotate([0, 0, 90]) 
            difference() {
                // 1. THE OUTER SHELL
                // We translate it so Z=0 is the "Floor" (track surface)
                translate([-out_w/2, 0, -0.35])
                    cube([out_w, out_l, out_h+0.35]);
        
                // 2. THE MOTOR CUTOUT
                // Positioned so the bottom of the motor is exactly 'gndcl' above Z=0
                translate([-m_w/2 - tolerance/2, -tolerance, gndcl + wall_thickness])
                    cube([m_w + tolerance, m_l + tolerance * 2, m_h + tolerance]);
        
                // 3. SHAFT HOLE
                // Positioned at gndcl + wall + half motor height
                translate([0, 0.1, gndcl + wall_thickness + shaft_offset_z])
                    rotate([90, 0, 0])
                    cylinder(h = 1.5, r = 0.3 + tolerance, $fn = 24);
        
                // 4. TOP SNAP-IN SLOT
                snap_width = m_w - 0.15; // Slightly tighter for better grip
                translate([-snap_width/2, -0.5, gndcl + wall_thickness + m_h/2])
                    cube([snap_width, out_l + 1, m_h + wall_thickness + 1]);
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

        
        module baseplate(w=0.5, gndcl=0.6) {
            union() {
                 // wheel axle
                wire([-8.5,0,0],[8.5,0,0],w);
        
                // central axle
                wire([0,0,0],[0,19.5,0],w);
        
                // front bumper
                difference() {
                translate([0,10,-0.08])
                difference() {
                        cylinder(w, 9, 10, center = true);
                        cylinder(h = 2, r = 8, center = true);
                        translate([-10,-26,-5])
                                cube([20,30,10]);
                        
                        
                }
                translate([3,18,0.65])
                rotate([0,0,-30])
                linear_extrude(height = 1, center = true)
                text(".da$ba", size=1.0);
                translate([-7.1,15.5,0.65])
                rotate([0,0,30])
                linear_extrude(height = 1, center = true)
                text("NXP CUP 2026", size=0.7);
                }

                

                // main plate
                translate([-5,0,0])
                trapez(10,5,11,0.2);

                wire([0,10,0],[8,15,0],w); // front bumper
                wire([0,10,0],[-8,15,0],w); // front bumper
                wire([-5,0,0],[-2.5,11.5,0],w); // left chas rod
                wire([5,0,0],[2.5,11.5,0],w); // right chas rod
                
                wire([-5,0,0],[2.5,11.5,0],w); // cross over
                wire([5,0,0],[-2.5,11.5,0],w); // cross over
        
                // bumper support
                wire([0,19,0],[5,13,0],w/2);
                wire([0,19,0],[-5,13,0],w/2);

                // bumper triangles
                triangle2d([[0,10,0],[0,19,0],[5,13,0]], h=0.1);
                triangle2d([[0,10,0],[0,19,0],[-5,13,0]], h=0.1);

                camera_support_right = get_node([5,0,0],[2.5,11.5,0],[4.6,2,0],[0,4,0]);
                sleeve_hub(camera_support_right, [[5,0,0],[2.5,11.5,0],[0,4,6]], rod_dia=0.4);
        
                camera_support_left = get_node([-5,0,0],[-2.5,11.5,0],[-4.6,2,0],[0,4,0]);
                sleeve_hub(camera_support_left, [[-5,0,0],[-2.5,11.5,0],[0,4,6]], rod_dia=0.4);
        
                camera_support_center = [0,9,0];
                sleeve_hub(camera_support_center, [[0,0,0],[0,20,0],[0,4,6]], rod_dia=0.4);
        
                frame_support_left_back = get_node([0,10,0], [-4.3,3,0], [-5,0,0],[-2.5,11.5,0]);
                sleeve_hub(frame_support_left_back, [[-5,0,0],[-2.5,11.5,0],center_point], rod_dia=0.4);
        
                frame_support_right_back = get_node([0,10,0], [4.3,3,0], [5,0,0],[2.5,11.5,0]);
                sleeve_hub(frame_support_right_back, [[5,0,0],[2.5,11.5,0],center_point], rod_dia=0.4);
        
                frame_support_left_front = get_node([0,10,0], [-2.5,11.5,0], [-5,0,0],[-2.5,11.5,0]);
                sleeve_hub(frame_support_left_front, [[-5,0,0],center_point], rod_dia=0.4);
        
                frame_support_right_front = get_node([0,10,0], [2.5,11.5,0], [-5,0,0],[2.5,11.5,0]);
                sleeve_hub(frame_support_right_front, [[5,0,0],center_point], rod_dia=0.4);

                wheel_suport_connect_right = get_node([4,5,0],[8,0,0],[5,0,0],[2.5,11.5,0]);
                sleeve_hub(wheel_suport_connect_right, [[5,0,0],[8,0,0],[2.5,11.5,0]]);

                wheel_suport_connect_left = get_node([-4,5,0],[-8,0,0],[-5,0,0],[-2.5,11.5,0]);
                sleeve_hub(wheel_suport_connect_left, [[-5,0,0],[-8,0,0],[-2.5,11.5,0]]);
        
                frame_support_bumper = [0,19,0.2];
                sleeve_hub(frame_support_bumper, [center_point], rod_dia=0.4);

            }
        }

        module cameraMount() {
            union() {
                rotate([0,0,180])
                translate([0,-4,5])
                cameraHolder(wall_thickness = 0.2, tolerance = 0.05);
                difference() {
                sleeve_hub([0.8,3.65,5],[[4.6,2,0]], rod_dia=0.4); //right
                translate([0,4,9 - 4.191/2])
                camera();
                }
                difference() {
                sleeve_hub([-0.8,3.65,5],[[-4.6,2,0]], rod_dia=0.4); //left
                translate([0,4,9 - 4.191/2])
                camera();
                }
                difference() {
                sleeve_hub([0,4.85,5],[[0,9,0],[0,10,2]], rod_dia=0.4); //center
                translate([0,4,9 - 4.191/2])
                camera();
                }
                
            }
        }

        module motorMount(w = 0.5, gndcl = 0.6) {
            // right motor holder
            difference() {
                translate([8.5,0,0])
                difference() {
                    motorHolder(gndcl = gndcl, wall_thickness = 0.2, tolerance = 0.03);
                    translate([-2,0,-1])
                    cylinder(h=1,r=0.125, $fn=6);
                    translate([-1,0,-1])
                    cylinder(h=1,r=0.125, $fn=6);
                }
                wire([-8.5,0,0],[8.5,0,0],w + 0.03);
                wire([4,5,0],[8,0,0], w + 0.03);
                wire([4,-5,0],[8,0,0], w + 0.03);
            }
        }

        module props(w = 0.5, gndcl = 0.6) {
            translate([8.5,-0.5,2.1-(gndcl+w/2) - 0.6])
            motor();
    
            rotate([0,0,180])
            translate([8.5,-0.5, 2.1-(gndcl+w/2) - 0.6])
            motor();
    
            // Test render it
            translate([0,4,9 - 4.191/2])
            camera();
    
            translate([10-0.8,0,2.1-(gndcl+w/2)])
            wheel();
    
            // 0 -> 2.1 - 0.6
            translate([-10-0.8,0,2.1-(gndcl+w/2)])
            wheel();

            translate([-3.7,0,0.3])
            battery();
    
        }
       
        width = 20;
        w = 0.5;
        gndcl = 0.6;

        // camera holder
        cameraMount();

        // base plate
        baseplate(w = 0.5, gndcl = 0.6);

        // right motor mount
        motorMount();

        // left motor mount
        rotate([0,0,180])
        motorMount();
        
        // models for battery motors etc
        props();

        // central camera support triangle
        rotate([0,90,0])
        triangle2d([[0,9,0],[0,6,0],[-5, 5,0]], h=0.1);

        //camera supports
        wire([0,9,0],[0,4,6],0.4); // center
        wire([4.6,2,0],[0,4,6],0.4); // right
        wire([-4.6,2,0],[0,4,6],0.4); // left

        //whell support
        wire([4,5,0],[8,0,0],w);
        wire([-4,5,0],[-8,0,0],w);

        center_point = [0,10,2];

        frame_support_center = [0,10,2];
        sleeve_hub(frame_support_center, [[-4.3,3,0],[-2.5,11.5,0],[4.3,3,0],[2.5,11.5,0],[0,4,6],[0,19,0]], rod_dia=0.4);

        translate([0,6.5,0])
        rotate([0,-90,0])
        side_clasp(rod_dia=0.4);

        translate([0,6.75,2.7])
        rotate([-50,0,0])
        rotate([0,90,0])
        side_clasp(rod_dia=0.4);

        wire([-2.5,11.5,0],center_point,0.4);
        wire([2.5,11.5,0],center_point,0.4);
        wire([0,19,0.2],center_point,0.4);
        wire(center_point,[0,4.85,5],0.4);
        //wire(center_point,[0,9,0],0.4);
        wire(center_point,[4.3,3,0],0.4);
        wire(center_point,[-4.3,3,0],0.4);
}


translate([0,9,0]) // for animation
rotate([0,0,360*$t])
        translate([0,-9,0])
        wirefollower();


//Im making a car for a competition. Because my oponents have massive, complex cars (with bigger processors, suspension, and much more) <more than 500g i think> i decided to go the other way, by making my car as light and as simple as possible in order to obtain a 30s laptime on a 20m track. Do you think this is good? (i consider replacing the battery with 2s, im using N20 1000RPM motors that we will limit electronically, and consider good printing) 

