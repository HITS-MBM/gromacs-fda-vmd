# GROMACS-FDA-VMD

Tcl scripts are used to read and represent in VMD scalar pairwise interactions;
there is no representation for vector pairwise interactions.

## Usage of pf_loaduser

Per-atom data is loaded into the “user” field that each atom has assigned in
VMD; this field can be used to set the color of the atom. An animation can be
produced by updating the value in this field for each frame, showing the
variations in per-atom data as they vary in time. To load and use the
pf_loaduser plugin, follow the syntax:

```
package require pf_loaduser
pf_loaduser <filename.pfa> <residues_renumbered> <ignore_zeros> <color_scale> <color_min> <color_max>
```

The first line will instruct VMD to load the pf_loaduser plugin which will make
available the pf_loaduser function which is called on the 2nd  line. The
pf_loaduser function takes several arguments:

filename.pfa is a string representing the name of the file containing per-atom
data; it assumes that there are as many lines with data in the file as there
are currently loaded frames. There is no default, a file name should always be
provided.  residues_renumbered is a string containing “true” or “false”. It
should correspond to whether a residue renumbering has been done (automatically
or enforced) in the GROMACS PF2 code. The default is “false”.  ignore_zeros is
an integer; if set to 0, zeros will be taken into consideration when
calculating the minimum values, if set to something else, zeros will not be
taken into consideration when calculating minimum values. The default is 0.
This is useful for the case when analyzing only a subset of atoms in which case
the atoms not analyzed will have a zero value. If color_min is given,
ignore_zeros will not have any effect.  color_scale is a string representing
the name of the VMD color scale. The default is “BGR”.  color_min and color_max
are floating point numbers representing the minimum and maximum values used for
color mapping, useful when doing a uniform mapping for several trajectories; if
they are not specified or specified as “-1”, the minimum and maximum values
found in the file will be used.

At the end of loading a per-atom/per-residue data file, the Tcl script will
print the minimum and maximum values used for color mapping.  Example for using
the pf_loaduser plugin: load a PDB file and a trajectory then at the console or
in the Tk console type:

```
package require pf_loaduser
animate delete beg 0 end 0 skip 0 0
pf_loaduser "peratom-sum.pfa"
```

The second line tells VMD to remove the first frame – this is needed as the PDB
will act as the first frame and the .pfa file contains only as many frames as
there are in the trajectory. The third line loads the user data from the
“peratom-sum.pfa” file and lets VMD automatically map the colors using the
minimum and maximum value from this file.

As the data is assigned to the per-atom “user” field, VMD takes care of
updating the colors when drawing each frame. For residue-based data, all atoms
in a residue receive the same per-atom “user” data.

## Usage of pf_draw

Scalar pairwise forces are represented as a set of cylinders drawn for each
pair between the coordinates of the 2 atoms. The scalar values are mapped to
either thickness or color of cylinders. To load and use the pf_draw plugin,
follow the syntax:

```
package require pf_draw
pf_init <max_cylinder_width> <what_to_scale>
pf_read <filename.pfa> <residues_renumbered>
pf_draw
```

The first line will instruct VMD to load the pf_draw plugin which will make
available functions shown on the 2nd  to 4th line.  The second line initializes
the plugin: max_cylinder_width is a floating point number specifying the
maximum cylinder width; what_to_scale is either “cyl_w” - scale width or
“cyl_col” - scale color.  The third line reads scalar pairwise force data (as
output with atombased set to scalar) from the specified file;
residues_renumbered is a string containing “true” or “false” and should
correspond to whether a residue renumbering has been done (automatically or
enforced) in the GROMACS PF2 code - the default is “false”.  The fourth line
draws the cylinders for the currently active structure (a PDB file or the last
frame of a trajectory); any cylinders drawn previously are removed before
drawing new ones.  When scaling the cylinder width, the maximum cylinder width
is taken from the pf_init command line. For each pair of atoms, the value used
as cylinder width is the absolute value of the pairwise force. To show the sign
of the pairwise forces, the cylinders are colored red for positive pairwise
forces and blue for negative ones (zero forces can't be visualized as the
cylinder width would be zero).  When scaling the cylinder color, the cylinder
width is taken from the pf_init command line. For each pair of atoms, the value
used as cylinder color is the value of the pairwise force scaled such that the
minimum pairwise force corresponds to the lowest color, the maximum pairwise
force corresponds to the maximum color and a zero pairwise force corresponds to
the midpoint of the color scale.  At the end of reading a scalar pairwise
forces file, the Tcl script will print the difference between the maximum and
minimum force in the set; this difference is used for color scaling.  Example
for using the pf_loaduser plugin: load a PDB file and a trajectory then at the
console or in the Tk console type:

```
package require pf_draw
animate delete beg 0 end 0 skip 0 0
pf_init 0.2 "cyl_w"
pf_read "summed_scalar.pfa"
trace variable vmd_frame(0) w pf_draw
```

The second line tells VMD to remove the first frame – this is needed as the PDB
will act as the first frame and the .pfa file contains only as many frames as
there are in the trajectory. The third line will initialize the drawing to
scale by cylinder width, with a maximum cylinder width of 0.2 – this value
needs experimentation. The fifth line looks a bit strange – it tells VMD to
call the function pf_draw for each drawing of a frame; this is needed because
VMD doesn't know what to do with the pairwise forces values. If this line would
be replaced by a simple pf_draw, cylinders would be drawn for the currently
loaded PDB file or last frame of the trajectory but they would not be updated
when VMD displays a different frame.  If there are many pairwise forces to be
represented, drawing the cylinders from a Tcl function can become slow and the
display can become cluttered with so many geometrical shapes. It's recommended
to filter the pairwise forces, so that only a few are represented at a time.

