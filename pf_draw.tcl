# copyright Bogdan Costescu 2010-2012

# to use:
#
# package require pf_draw
# pf_init 0.2 "cyl_w"
# pf_read "summed-scalar.pfa"
# trace variable vmd_frame(0) w pf_draw
#

# when residues are not renumbered, it's possible that they don't start at 1
# or that they have wholes in numbering; in this case, "resid" selection can
# be used to identify the Calpha, however the method of dumping all coordinates
# at once doesn't work anymore, the selections have to be done individually
# which will be slower.

package provide pf_draw 20120829

# pf_draw_what can be "cyl_w" (scale width) or "cyl_col" (scale color)
global pf_draw_what
global pf_cyl_w
global pf_min_f
global pf_max_f
global pf_minmax
global pf_x
global pf_data
global pf_graph
global pf_residues
global pf_resrenum

# pf_init sets the maximum cylinder width and set the min and max force such
# that usual values are smaller/larger respectively
proc pf_init {cylw what} {
	global pf_cyl_w
	global pf_min_f
	global pf_max_f
	global pf_draw_what
	set pf_cyl_w $cylw
	set pf_draw_what $what
	set pf_min_f 9.9e20
	set pf_max_f -9.9e20
	set pf_resrenum false
	puts "initialization finished"
}

# pf_init_x should be called once per frame and sets pf_x to the current coords
proc pf_init_x {} {
	global pf_x
	global pf_residues
	global pf_resrenum
	# if dealing with residues and pf_resrenum is false, don't do anything as pf_x will not be used
	if {($pf_residues == 1 && $pf_resrenum == false)} {
		return
	}
	# the selection based on mass below is to distinguish between Calpha
	# and Calcium atoms which are often both called CA
	if {$pf_residues == 1} then {
		set sel [atomselect top "name CA and mass 12 to 17"]
	} else {
		set sel [atomselect top all]
	}
	set pf_x [$sel get {x y z}]
	$sel delete
}

# pf_draw_cyl_w makes a cyclinder between positions of atoms i and j of width
# corresponding to force f (scaled by pf_cyl_w and pf_max_f)
# i and j are 0-based indeces, corresponding to those used in VMD and
# internally in GROMACS
proc pf_draw_cyl_w {i j f} {
	global pf_cyl_w pf_min_f pf_max_f pf_x
	global pf_residues
	global pf_resrenum
	set r [expr abs($f * $pf_cyl_w / $pf_max_f)]
	if {$f > 0} {
		set color "red"
	} else {
		set color "blue"
	}
	draw color $color
	if {($pf_residues == 1 && $pf_resrenum == false)} {
		set sel_i [atomselect top "resid $i and name CA and mass 12 to 17"]
		set sel_j [atomselect top "resid $j and name CA and mass 12 to 17"]
		# get the coordinates
		lassign [$sel_i get {x y z}] pos_i
		lassign [$sel_j get {x y z}] pos_j
		# remove the selections
		$sel_i delete
		$sel_j delete
		draw cylinder $pos_i $pos_j radius $r filled yes
	} else {
		draw cylinder [lindex $pf_x $i] [lindex $pf_x $j] radius $r filled yes
	}
}

# pf_draw_cyl_col makes a cyclinder between positions of atoms i and j of width
# given by pf_cyl_w and color corresponding to force f (scaled by pf_min/max_f);
# the color scale is set such that a zero force corresponds its midpoint;
# i and j are 0-based indeces, corresponding to those used in VMD and
# internally in GROMACS
proc pf_draw_cyl_col {i j f} {
	global pf_cyl_w
	global pf_min_f
	global pf_minmax
	global pf_x
	global pf_residues
	global pf_resrenum
	set color_in_scale [expr 1023 * ($f - $pf_min_f)/$pf_minmax]
	if {$color_in_scale < 0} {
		set color_in_scale 0
	} elseif {$color_in_scale > 1023} {
		set color_in_scale 1023
	}
	set color [expr 33 + $color_in_scale]
	draw color $color
	if {($pf_residues == 1 && $pf_resrenum == false)} {
		set sel_i [atomselect top "resid $i and name CA and mass 12 to 17"]
		set sel_j [atomselect top "resid $j and name CA and mass 12 to 17"]
		# get the coordinates
		lassign [$sel_i get {x y z}] pos_i
		lassign [$sel_j get {x y z}] pos_j
		# remove the selections
		$sel_i delete
		$sel_j delete
		draw cylinder $pos_i $pos_j radius $pf_cyl_w filled yes
	} else {
		draw cylinder [lindex $pf_x $i] [lindex $pf_x $j] radius $pf_cyl_w filled yes
	}
}

# pf_data is a list, each element corresponding to a frame
# each of the above elements is a list, each element corresponding to a PF
# each of the above elements is a list, with the format: i j force ftype
proc pf_draw {args} {
	global pf_data
	global pf_graph
	global pf_x
	global pf_min_f
	global pf_max_f
	global pf_minmax
	global pf_draw_what
	set frame [molinfo top get frame]
	if {[info exists pf_graph]} then {
		foreach g $pf_graph { graphics top delete $g }
		set pf_graph [list]
	}
	if {[info exists pf_data($frame)]} then {
		pf_init_x
		# it looks bad to repeat code, but this is done for performance
		# to avoid a test in the loop
		if {$pf_draw_what == "cyl_w"} {
			foreach pf $pf_data($frame) {
				lassign $pf i j force ftype
				lappend pf_graph [pf_draw_cyl_w $i $j $force]
			}
		} elseif {$pf_draw_what == "cyl_col"} {
			# if pf_min_f and pf_max_f have the same sign, the
			# color scale midpoint should be left as it is (in the
			# middle), else it should be set to correspond to a
			# zero force
			if {$pf_max_f * $pf_min_f < 0} {
				color scale midpoint [expr (0.0 - $pf_min_f)/$pf_minmax]
			}
			foreach pf $pf_data($frame) {
				lassign $pf i j force ftype
				lappend pf_graph [pf_draw_cyl_col $i $j $force]
			}
		}
	}
}

proc pf_read {fname {residues_renumbered false}} {
	global pf_data
	global pf_min_f
	global pf_max_f
	global pf_minmax
	global pf_residues
	global pf_resrenum
	set pf_resrenum $residues_renumbered
	# check whether it's a file containing residue data
	set fnamelen [string length $fname]
	if {[string compare [string tolower [string range $fname [expr $fnamelen - 4] $fnamelen]] ".pfr"] == 0} {
		set pf_residues 1
	} else {
		set pf_residues 0
	}
	if {$pf_residues == 1} then {
		puts "now loading inter-residue pairwise forces"
	} else {
		puts "now loading inter-atom pairwise forces"
	}
	set f [open $fname r]
	set framecount [molinfo top get numframes]
	while {1} {
		set line [gets $f]
		if {[eof $f]} {
			close $f
			break
		}
		set l [split $line]
		if {[lindex $l 0] == "frame"} {
			set frame [lindex $l 1]
			continue
		}
		lappend pf_data($frame) $l
		# need to get the min and max of force for scaling
		lassign $l i j force ftype
		if {$force < $pf_min_f} {
			set pf_min_f $force
		}
		if {$force > $pf_max_f} {
			set pf_max_f $force
		}
	}
	# pf_min_f and pf_max_f are only modified here, so compute pf_minmax
	# here as well, to avoid computing it repeatedly somewhere else
	set pf_minmax [ expr $pf_max_f - $pf_min_f ]
	puts "pf_minmax=$pf_minmax"
}

