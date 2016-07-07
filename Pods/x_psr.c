//
//  x_psr.c
//  PassiveSensors
//
//  Created by Kevin Schlei on 6/13/16.
//  Copyright © 2016 labuser. All rights reserved.
//

#include "m_pd.h"

#include <string.h>
#include <stdio.h>
extern t_pd *newest;

/*
 NOTE: to install this into libpd, first add this file to the libpd project. Next...
 
 1. add to m_pd.h:
 EXTERN void psrControllerRequest(const char *s);
 
 2. add to m_pd.c:
 void x_psr_setup(void);
 
 3. add to m_pd.c pd_init{...:
 x_psr_setup();

 */

/* -------------------- psreceive ------------------------------ */

static t_class *psr_class;

typedef enum {
    Linear = 0,
    EaseIn = 1,
    EaseOut = 2,
    EaseInOut = 3
} t_slope;

typedef struct _psr
{
    t_object x_obj;
    t_symbol *x_sym;
    t_float x_min;
    t_float x_scale;
    t_slope x_slope;
} t_psr;

static void psr_bang(t_psr *x)
{
    outlet_bang(x->x_obj.ob_outlet);
}

static t_float slopeValue(t_psr *x, t_float f) {
    //slope the incoming value
    switch (x->x_slope) {
        case Linear:
            break;
        case EaseIn:
        {
            f = f * f;
        }
            break;
        case EaseOut:
        {
            t_float inv = 1.0 - f;
            f = 1.0 - (inv * inv);
        }
            break;
        case EaseInOut:
        {
            if (f <= 0.5) {
                t_float df = f * 2.0;
                f = (df * df) * 0.5;
            }
            else {
                t_float df = (f - 1.0) * 2.0;
                f = (1.0 - (df * df)) * 0.5 + 0.5;
            }
        }
            break;
        default:
            break;
    }
    return f;
}

static void psr_float(t_psr *x, t_float f)
{
    //slope the incoming value
    f = slopeValue(x, f);
    
    //map the incoming normalized value (expected) to min, max range:
    t_float scaled = (f * x->x_scale) + x->x_min;
    outlet_float(x->x_obj.ob_outlet, scaled);
}

static void psr_symbol(t_psr *x, t_symbol *s)
{
    outlet_symbol(x->x_obj.ob_outlet, s);
}

static void psr_pointer(t_psr *x, t_gpointer *gp)
{
    outlet_pointer(x->x_obj.ob_outlet, gp);
}

static void psr_list(t_psr *x, t_symbol *s, int argc, t_atom *argv)
{
    //map the incoming normalized value (expected) to min, max range:
    t_float value = atom_getfloatarg(1, argc, argv);
    
    //slope the incoming value
    value = slopeValue(x, value);
    
    t_float scaled = (value * x->x_scale) + x->x_min;
    argv[1].a_w.w_float = scaled;
    outlet_list(x->x_obj.ob_outlet, s, argc, argv);
}

static void psr_anything(t_psr *x, t_symbol *s, int argc, t_atom *argv)
{
    outlet_anything(x->x_obj.ob_outlet, s, argc, argv);
}

static void *psr_new(t_symbol *s, t_floatarg min, t_floatarg max, t_symbol *slope)
{
    t_psr *x = (t_psr *)pd_new(psr_class);
    x->x_sym = s;
    
    x->x_min = min;
    x->x_scale = max - min;
    
    if (strcmp(slope->s_name,"Linear") == 0) {
        x->x_slope = Linear;
    }
    if (strcmp(slope->s_name,"EaseIn") == 0) {
        x->x_slope = EaseIn;
    }
    if (strcmp(slope->s_name,"EaseOut") == 0) {
        x->x_slope = EaseOut;
    }
    if (strcmp(slope->s_name,"EaseInOut") == 0) {
        x->x_slope = EaseInOut;
    }
    
    pd_bind(&x->x_obj.ob_pd, s);
    outlet_new(&x->x_obj, 0);

    //report up to BSPdListener that this controller name was requested:
    psrControllerRequest(s->s_name);
    
    return (x);
}

static void psr_free(t_psr *x)
{
    pd_unbind(&x->x_obj.ob_pd, x->x_sym);
}

static void psr_setup(void)
{
    psr_class = class_new(gensym("psr"), (t_newmethod)psr_new,
                          (t_method)psr_free, sizeof(t_psr), CLASS_NOINLET, A_DEFSYM, A_DEFFLOAT, A_DEFFLOAT, A_DEFSYM, 0);
    class_addbang(psr_class, psr_bang);
    class_addfloat(psr_class, (t_method)psr_float);
    class_addsymbol(psr_class, psr_symbol);
    class_addpointer(psr_class, psr_pointer);
    class_addlist(psr_class, psr_list);
    class_addanything(psr_class, psr_anything);
}

/* -------------- overall setup routine for this file ----------------- */

void x_psr_setup(void)
{
    psr_setup();
}
