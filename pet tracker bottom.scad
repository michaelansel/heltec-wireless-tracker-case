// file: pet tracker bottom.scad
// desc: OpenSCAD file for Heltec Wireless Tracker Case
// author: Matthew Clark, mclark@gorges.us
// website: https://gorges.us
// github: https://github.com/GORGES
// license: Attribution-ShareAlike (mention author, keep license)
// date: 8/14/2024

// global settings

$fs = 0.03;   // set to 0.01 for higher definition curves

// BOM parameters (fixed)

// Heltec Wireless Tracker
$pcb_width = 28.1;
$pcb_length = 63.8;
$pcb_thickness = 1.7;
// (compound measurements)
$screen_thickness = 5.5-$pcb_thickness;
$gps_thickness = 5.70-$pcb_thickness;
$bt_ant_thickness = 6.4-$pcb_thickness;
$battery_plug_thickness = 8.6-$pcb_thickness-$screen_thickness; // lowest point on the board
// Included IPEX-SMA connector
$antenna_radius = 3.3;
// USB-C connector
// (connector is centered)
$usb_height = 3.5;
$usb_width = 9;
// MakerFocus 2000mAh Lithium battery
$battery_length = 53;
$battery_width = 34.2;
$battery_height = 10.3;

// Design parameters (adjustable)

$skin_thickness = 1.4;
$vertical_wiggle_room = 1; // so we don't pack things too tightly
$inside_radius = 2;
$outside_radius = 3;
$lip_height = 2.0;
$rail_thickness = 1.6; // how much the rail sticks out under the PCB

// Calculated parameters
$chip_length = $pcb_length + /*loss due to rounding*/ $inside_radius; // inside length
$chip_width = $pcb_width; // inside width
$usb_offset = $pcb_thickness; // bottom of usb above the rail
$lip_inset = $skin_thickness / 2;


// this could technically be a little tighter because the battery sits below the chips, not the battery plug, but a little extra space is probably a good idea
$minimal_chip_height = $battery_height+$battery_plug_thickness+$vertical_wiggle_room; // bottom of the pcb to the bottom interior
$case_y_max = $skin_thickness+$chip_width+$skin_thickness;

$battery_box_external_y_origin = $case_y_max - $skin_thickness - $battery_width - $skin_thickness;
$battery_box_y_extrusion = 0 - $battery_box_external_y_origin;
$antenna_center_x_offset = $skin_thickness + 2*$antenna_radius;
$battery_box_x_origin = $antenna_center_x_offset + 2*$antenna_radius;
$main_box_length = $chip_length + 2*$skin_thickness;
$case_x_max = $battery_box_x_origin + $skin_thickness + $battery_length + $skin_thickness;
$battery_box_x_extrusion = $case_x_max - $main_box_length;

$battery_box_outer_height =
    $skin_thickness + $battery_height + $skin_thickness // main dimensions
    + ($battery_box_y_extrusion - $skin_thickness); // avoid supports with a 45deg angled ceiling

$chip_height = (
    $minimal_chip_height > $battery_box_outer_height
        ? $minimal_chip_height
        : $battery_box_outer_height+2*$rail_thickness
);


$antenna_center_height = $chip_height // anchored against the rail location
    - 2*$rail_thickness // fully below the rail
    - $antenna_radius // spacing for the antenna hex
    - $antenna_radius; // center, not perimeter



// Old parameters
$rail_height = $chip_height - 1.2; // ??
$antenna_offset = $chip_width / 2;
$antenna_rail = 0.0;
$clasp_hole = 3.2;
$extra = 2;
$strap_angle = 8;
$strap_inset = 5.2;
$strap_offset = 3.3;
$strap_radius = 2.2;
$trough_radius = 2.2;

// rounded-cube function

module roundedcube(
    size = [1, 1, 1], radius = 1.0,
    x = false, y = false, z = false,
    xmin = false, ymin = false, zmin = false,
    xmax = false, ymax = false, zmax = false
) {
	// if single value, convert to [x, y, z] vector
	size = (size[0] == undef) ? [size, size, size] : size;
    all = !x && !xmin && !xmax && !y && !ymin && !ymax && !z && !zmin && !zmax;
    hull() {
        for (translate_x = [radius, size[0] - radius]) {
            x_at = (translate_x == radius) ? "min" : "max";
            for (translate_y = [radius, size[1] - radius]) {
                y_at = (translate_y == radius) ? "min" : "max";
                for (translate_z = [radius, size[2] - radius]) {
                    z_at = (translate_z == radius) ? "min" : "max";
                    translate(v = [translate_x, translate_y, translate_z])
                    if (all ||
                        x || (xmin && x_at == "min") || (xmax && x_at == "max") ||
                        y || (ymin && y_at == "min") || (ymax && y_at == "max") ||
                        (zmin && z_at == "min") || (zmax && z_at == "max")
                    ) {
                        sphere(r = radius);
                    } else {
                        rotate =
                            (x || xmin || xmax) ? [0, 90, 0] : (
                            (y || ymin || ymax) ? [90, 90, 0] :
                            [0, 0, 0]
                        );
                        rotate(a = rotate)
                        cylinder(h = 2 * radius, r = radius, center = true);
                    }
                }
            }
        }
    }
}

// bottom of case

module main_exterior() {
    union() {
        // box
        roundedcube(
            size = [
                $chip_length + 2 * $skin_thickness,
                $chip_width + 2 * $skin_thickness,
                $skin_thickness + $chip_height],
            radius = $outside_radius,
            zmin = true
        );
        // lip
        translate([
          $lip_inset,
          $lip_inset,
          $skin_thickness + $chip_height  / 2
        ])
        roundedcube(
            size = [
                $chip_length + 2 * ($skin_thickness - $lip_inset),
                $chip_width + 2 * ($skin_thickness - $lip_inset),
                $chip_height / 2 + $lip_height],
            radius = $outside_radius,
            zmin = true
        );
        // usb extra
        translate([
            0,
            $skin_thickness + ($chip_width - $usb_width) / 2,
            $skin_thickness + $chip_height
        ])
        cube([
            $skin_thickness,
            $usb_width,
            $lip_height
        ]);
        // battery
        translate([
            ($skin_thickness + 2*$antenna_radius) + 2*$antenna_radius,
            2*$skin_thickness+$chip_width - 2*$skin_thickness - $battery_width,
            0
        ])
        roundedcube(
            size=[
                $battery_length+2*$skin_thickness,
                $battery_width+2*$skin_thickness,
                $battery_box_outer_height
            ],
            radius=$outside_radius
        );
    };
}

module external_penetrations() {
    union() {
        // antenna
        translate([
            $skin_thickness + $antenna_radius + $antenna_radius,
            2*$extra,
            //$skin_thickness + ($rail_height-$rail_thickness) / 2
            $antenna_center_height
        ])
        rotate([90, 0, 0])
        cylinder(h = $skin_thickness + 6 * $extra, r = $antenna_radius);
        // clasp holes
        for (offset_x = [$chip_length / 3, 2 * $chip_length / 3]) {
            translate([
                $skin_thickness + offset_x - $clasp_hole / 2,
                -$extra,
                $skin_thickness + $chip_height
            ])
            cube([
                $clasp_hole,
                2 * $skin_thickness + $chip_width + 2 * $extra,
                $lip_height / 2
            ]);
        }
        // usb port
        translate([
            -$extra,
            $skin_thickness + ($chip_width - $usb_width) / 2,
            $skin_thickness + $chip_height + $lip_height - $usb_offset
        ])
        roundedcube(
            size = [
                2 * $extra + $skin_thickness,
                $usb_width,
                $usb_height],
            radius = 0.8,
            x = true
        );
        // strap holes
        *for (offset_x = [0, 2 * $skin_thickness + $chip_length]) {
            for (offset_y = [0, 2 * $skin_thickness + $chip_width]) {
                translate([offset_x, offset_y, $skin_thickness + $strap_offset])
                rotate_extrude(angle = 360)
                translate([$skin_thickness + $strap_inset, 0, 0])
                circle(r = $strap_radius);
            }
        }
    }
}

module internal_voids() {
    union() {
        // center void
        translate([
            $skin_thickness,
            $skin_thickness,
            $skin_thickness
        ])
        roundedcube(
            size = [
                $chip_length,
                $chip_width,
                $skin_thickness + $chip_height + $lip_height + $extra],
            radius = $inside_radius
        );
        // battery
        translate([
            ($skin_thickness + 2*$antenna_radius) + 2*$antenna_radius + $skin_thickness,
            2*$skin_thickness+$chip_width - 2*$skin_thickness - $battery_width + $skin_thickness,
            $skin_thickness
        ])
        roundedcube(
            size=[
                $battery_length,
                $battery_width,
                $battery_box_outer_height - 2*$skin_thickness
            ],
            radius=$inside_radius
        );
    }
}

module internal_additions() {
    union() {
        // chip rails
        translate([
            $skin_thickness,
            $skin_thickness,
            $skin_thickness + $rail_height
        ])
        rotate([0, 90, 0])
        linear_extrude(height = $chip_length)
        polygon(points = [
            [0, 0],
            [2 * $rail_thickness, 0],
            [0, $rail_thickness]
        ]);
        translate([
            $skin_thickness,
            $skin_thickness + $chip_width,
            $skin_thickness + $rail_height
        ])
        rotate([0, 90, 0])
        linear_extrude(height = $chip_length)
        polygon(points = [
            [0, 0],
            [2 * $rail_thickness, 0],
            [0, -$rail_thickness]
        ]);
        
        // battery overhang support avoidance
        // length
        translate([
            ($skin_thickness + 2*$antenna_radius) + 2*$antenna_radius + $skin_thickness,
            2*$skin_thickness+$chip_width - 2*$skin_thickness - $battery_width + $skin_thickness,
            $battery_box_outer_height - $skin_thickness
        ])
        rotate([0, 90, 0])
        linear_extrude(height = $battery_length)
        polygon(points = [
            [0, 0],
            [$battery_box_y_extrusion, 0],
            [0, $battery_box_y_extrusion]
        ]);
        // width
        translate([
            ($skin_thickness + 2*$antenna_radius) + 2*$antenna_radius + $skin_thickness + $battery_length,
            0-$battery_box_y_extrusion+$skin_thickness,
            $battery_box_outer_height - $skin_thickness
        ])
        rotate([0, 90, 90])
        linear_extrude(height = $battery_width)
        polygon(points = [
            [0, 0],
            [$battery_box_x_extrusion, 0],
            [0, $battery_box_x_extrusion]
        ]);
        
        // antenna rails
        *translate([
            $skin_thickness + $chip_length - $antenna_rail,
            $antenna_offset - $antenna_radius,
            $skin_thickness
        ])
        cube([
            $antenna_rail,
            $skin_thickness,
            $rail_height / 2 + $antenna_radius
        ]);
        *translate([
            $skin_thickness + $chip_length - $antenna_rail,
            $skin_thickness + $antenna_offset + $antenna_radius,
            $skin_thickness
        ])
        cube([
            $antenna_rail,
            $skin_thickness,
            $rail_height / 2 + $antenna_radius
        ]);
        *translate([
            $skin_thickness + $chip_length - $antenna_rail,
            $antenna_offset - $antenna_radius,
            $skin_thickness
        ])
        cube([
            $skin_thickness,
            2 * $skin_thickness + 2 * $antenna_radius,
            $rail_height / 2 - $antenna_radius
        ]);
        // strap tubes
        *for (offset_x = [0, 2 * $skin_thickness + $chip_length]) {
            for (offset_y = [0, 2 * $skin_thickness + $chip_width]) {
                translate([offset_x, offset_y, $skin_thickness + $strap_offset])
                rotate([
                    0,
                    0,
                    (offset_x
                        ? (offset_y ? 180 + $strap_angle : 90 + $strap_angle)
                        : (offset_y ? -90 + $strap_angle : $strap_angle))
                ])
                rotate_extrude(angle = 90 - 2 * $strap_angle)
                translate([$skin_thickness + $strap_inset, 0, 0])
                difference() {
                    circle(r = $skin_thickness + $strap_radius);
                    circle(r = $strap_radius);
                };
            }
        }
    }
}

union() {
    difference() {
        main_exterior();
        external_penetrations();
        internal_voids();
    }
    
    internal_additions();
}
