use <parametric_involute_gear_v5.0.scad>
use <spur_generator.scad>

// constant
// C0Constant = 28.9748; // hypothetical
C0Constant = 24.3648631; // empirical

function teeth_length( n ) = ( C0Constant * teeth / 2.0 ) * sqrt( 1.0 / pow(2.0, n/12 ));
function overall_teeth_width( teeth, gap, teethNum ) = teeth * numTeeth + gap * (numTeeth - 1);

module base( resize = 1.0, gap = 2.1, teeth = 1.5, numTeeth = 12 ) {
	difference() {
		cube([( teeth * numTeeth + gap * (numTeeth - 1) ) + 3.0, 9.9, 3.0 + 3.0], true);
		// hole
		cube([teeth * numTeeth + gap * (numTeeth - 1), 10.0, 2.0], true);
		translate( [-(teeth * numTeeth + gap * (numTeeth - 1))/2,0,0 ]) cube([1.0, 10.0, 4.0], true );
		translate( [(teeth * numTeeth + gap * (numTeeth - 1))/2,0,0 ]) cube([1.0, 10.0, 4.0], true );
	}
	translate([0,0,-6.75]) cube([5.0, 9.9, 10.0], true);
	translate([0,15 - 9.9/2,-12]) cube([teeth * numTeeth + gap * (numTeeth - 1)*1.25, 30, 1.0], true);
} 

// in teeth parameter 0 is C0
module teeth_part( resize = 1.0, gap = 2.1, teeth = 1.5, numTeeth = 12, teethElement = [ 0:11 ] ) {
    offset = 0.1;
    longestTeeth = ( C0Constant * teeth / 2.0 ) *  sqrt( 1.0 / pow(2.0, min(teethElement)/12 ));
    teethThickness = teeth / 2.0 * 0.9;
    
    difference(){
        baseLength = 15.0;
        baseOffset = 2.0;
        union() {
            cube([teeth * numTeeth + gap * (numTeeth - 1), baseLength, baseOffset - offset * 2 ], true);
            
            // base and teeth connector
            for ( i = [0 : numTeeth-2] ) {
                linear_extrude(height = 2.0 - (offset*2), center = true, convexity = 10, twist = 0) 
                translate([overall_teeth_width(teeth,gap,teethNum) / 2 - ( teeth + gap ) * i - teeth,7.5,0]) 
                rotate([0,0,90]) 
                polygon(points = [[0,0],[0,gap],
                                    [longestTeeth - teeth_length( teethElement[i+1] ) ,gap],
                                    [longestTeeth - teeth_length(teethElement[i]),0]], 
                                    paths = [[0,1,2,3]]);
            }
            
            // teeth
            overallX = teeth * numTeeth + gap * (numTeeth - 1);
            
            for ( i = [0 : numTeeth-1] ) {
                teethLength = ( C0Constant * teeth / 2.0 ) *  sqrt( 1.0 / pow(2.0, teethElement[i]/12 ));
                translate([0,0,-teethThickness + (1.0 - offset )])
                translate([overallX / 2 - teeth - ( i * (teeth + gap) ) ,7.5 + longestTeeth - teethLength, 0]) { 
                    cube( [ teeth, teethLength, teethThickness] );
                    // Mick Part
                    translate([0,teethLength,-teethThickness/2]){
                        mirror([0,1,0])cube( [ teeth, teethLength/2, teethThickness/2] );
                        translate([0,0,-teethThickness/2]){
                            mirror([0,1,0])cube( [ teeth, teethLength/4, teethThickness/2] );
                        }
                    }
                    //translate([0,0,-3*teethThickness])
                    //cube( [ teeth, teethLength/8, teethThickness] );
                }
                translate([overall_teeth_width( teeth, gap, teethNum) / 2 + -i * (gap+teeth) - teeth,7.5,-1 + offset]) cube([teeth,longestTeeth - teethLength,2 - 2*offset]);
            }
        }// end region union
        
        // subtractive elements
        for ( i = [0 : numTeeth-1] ) {
                    teethLength = ( C0Constant * teeth / 2.0 ) *  sqrt( 1.0 / pow(2.0, teethElement[i]/12 ));
                    translate([0,0,-teethThickness + (1.0 - offset )])
                    translate([overall_teeth_width( teeth, gap, teethNum) / 2 + -i * (gap+teeth) - teeth - 0.5,baseLength/12+longestTeeth-teethLength,-baseOffset-0.5 + offset]) cube([teeth+gap+2,/*longestTeeth - teethLength*/baseOffset,baseOffset]);
        }
    }
    
    
    
    
}

module pin( dimension = [2,2,2], angle = 45 ) {
    cube( dimension, center = true );
    linear_extrude(height = dimension[2], center = true) translate([-dimension[0]/2,dimension[1]/2,0])  polygon(points = [[0,0],[0,dimension[1]],[dimension[1] * tan(angle),0]], paths = [[0,1,2]]);
}

module sub_cylinder_part ( gap = 2.1, teeth = 1.5, numTeeth = 12, radius = 2.5, noteElement = [ 0,1,2,3,4,5,6,7,8,9,10,11 ] ) {
    
    cylinder( h=overall_teeth_width(gap,teeth,numTeeth) + teeth * 2 , r = radius, center = true, $fn = 100 );
    for ( i = [ 0 : len(noteElement) - 1 ] ) {
        if ( noteElement[i] >= 0 ) {
           
            translate([0,0,overall_teeth_width(gap,teeth,numTeeth)/2 - teeth / 2 - ( gap + teeth ) *noteElement[i]]) 
            rotate([0,0,i * 360 / len(noteElement) ])  
            translate([0,radius+teeth/2 - 0.5,0]) 
            rotate([90,0,90]) 
            pin([teeth,teeth,teeth/2], 45);
        }
    }
    
    // gear part
    n1 = 20; n2 = 20;
	p = fit_spur_gears(n1, n2, radius*1.5);
	
    translate([0,0,-overall_teeth_width(gap,teeth,numTeeth)/2 - teeth])
    union() {
        rotate([0,180,0])
	gear (circular_pitch=p,
		gear_thickness = 0,
		rim_thickness = 2,
		hub_thickness = 0,
	    number_of_teeth = n1,
		circles=8);
        rotate([0,180,0])
        cylinder(h = 2, r = radius / 2);
    } 
   
   
    
    color("red")
    translate([0,0,-overall_teeth_width(gap,teeth,numTeeth)/2 - teeth - 0.5])
        rotate([0,0,90])
	translate([gear_outer_radius(n1, p) + gear_outer_radius(n2, p),0,0])

        rotate([0,180,0])
        union() {
	gear (circular_pitch=p,
		gear_thickness = 1.5,
		rim_thickness = 1.5,
		hub_thickness = 1.5,
		circles=8,
		number_of_teeth = n2,
		rim_width = 1);
        
        cylinder(h = 1.5, r = radius / 2);
    }
    
}

module cylinder_part ( gap = 2.1, teeth = 1.5, numTeeth = 12, radius = 2.5, noteElement = [ 0,1,2,3,4,5,6,7,8,9,10,11 ] ) {
    difference() {
        sub_cylinder_part ( gap, teeth, numTeeth, radius, noteElement );
        cylinder(h=overall_teeth_width(gap,teeth,numTeeth) * 1.5, r = 1, center = true, $fn = 100);
    }
}

module box_o_music_adhoc( inner_dim ) {

    difference() {
        translate([-1,35,0])
        cube([inner_dim[0]*1.1,inner_dim[1]*1.1,inner_dim[2]*0.9], center = true);
        translate([-1,35,0])
        cube(inner_dim, center = true);
    }
}

module box_o_music( inner_dim, outer_dim, hole_pos ) {
    
}

resize = 1.0;
gap = 1.0; 
teeth = 1.5; 
numTeeth = 12; 
teethElement = [ 0,1,2,3,4,5,6,7,8,9,10,11 ];
cylinder_radius = 10;
noteElement = [0,1,2,3,4,5,6,7,8,9,10,11,10,9,8,7,6,5,4,3,2,1];
//base(resize, gap, teeth, numTeeth);
teeth_part(resize, gap, teeth, numTeeth, teethElement);
//linear_extrude(height = 10, center = true, convexity = 10, twist = 0) 
//translate([0,40,0]) rotate([0,90,0])
//cylinder_part( gap, teeth, numTeeth, cylinder_radius, noteElement );

//color("green") box_o_music_adhoc( [overall_teeth_width(gap,teeth,numTeeth) + teeth * 2 + 2, 60, cylinder_radius * 2] );