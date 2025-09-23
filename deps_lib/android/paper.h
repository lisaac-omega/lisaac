#include <jni.h>
#include <EGL/egl.h>
//#include <GLES/gl.h>
#include <GLES3/gl3.h>
#include <GLES3/gl3ext.h>

#include <string.h>
#include <pthread.h>
#include <stdlib.h>

#include <android/log.h>
#include <android/asset_manager_jni.h>
#include <android/sensor.h>
#include <android_native_app_glue.h>

#define LOG_TAG ("LIA")
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__))
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__))
#define signal(x,y) 

#define lisaac_gl 0

struct android_app *my_app;

int stop;
extern JavaVM *JVM;   

void read_file(void *);
void delete_in(void *);
int draw_in(void *);
int term_window(void *);
int lost_focus(void *);
int init_gl(void *);
int init_pen(void *);
void *run_in(void *);
void mouse_action(void *,long,long,long,long);
int main(int,char **);

struct engine {
  struct android_app* app;
  void *pen;  
  int32_t stat;

  EGLDisplay display;
  EGLSurface surface;
  EGLContext context;
};

const EGLint attribs[] = {
  EGL_BLUE_SIZE,       8,
  EGL_GREEN_SIZE,      8,
  EGL_RED_SIZE,        8,
  EGL_ALPHA_SIZE,      8,
  EGL_DEPTH_SIZE,     16,
  EGL_STENCIL_SIZE,    8,
  EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
  0x3142 /*EGL_RECORDABLE_ANDROID*/, 1, // BSBS: Utile ???
  EGL_NONE
};
const EGLint contextAttribs[] = {
//  EGL_SURFACE_TYPE, 
//  EGL_WINDOW_BIT,
//  EGL_BLUE_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_RED_SIZE, 8,
  EGL_CONTEXT_CLIENT_VERSION, 3,
  EGL_NONE
};

// Begin Accelerometer
//const int LOOPER_ID_USER = 3;
#define SENSOR_REFRESH_RATE_HZ 100
#define SENSOR_REFRESH_PERIOD_US (1000000/SENSOR_REFRESH_RATE_HZ)
#define SENSOR_FILTER_ALPHA 0.1f

ASensorEventQueue *accelerometerEventQueue;
float acc_x,acc_y,acc_z;

void update_accelerometer()
{ ASensorEvent sensorEvent;
  float a = SENSOR_FILTER_ALPHA;
  while (ASensorEventQueue_getEvents(accelerometerEventQueue, &sensorEvent, 1) > 0) {
    acc_x = a * sensorEvent.acceleration.x + (1.0f - a) * acc_x;
    acc_y = a * sensorEvent.acceleration.y + (1.0f - a) * acc_y;
    acc_z = a * sensorEvent.acceleration.z + (1.0f - a) * acc_z;
    //LOGI("%d\n",sensorEvent.
  }
};
// End Accelerometer

void cmd_android(struct android_app* app, int32_t cmd)
{ struct engine* e = (struct engine *)(app->userData);
  e->stat = cmd;
  switch (cmd) {
    case APP_CMD_START:         LOGI("--> CMD %d : Start \n",cmd);         break;
    case APP_CMD_RESUME:        LOGI("--> CMD %d : Resume \n",cmd);        break;
    case APP_CMD_INPUT_CHANGED: LOGI("--> CMD %d : Input changed \n",cmd); break;    
    case APP_CMD_INIT_WINDOW:   LOGI("--> CMD %d : Init win \n",cmd);    
      init_gl(e);
      init_pen(e);
    break;
    
    case APP_CMD_DESTROY:       LOGI("--> CMD %d : Destroy \n",cmd);       break;    
    case APP_CMD_LOST_FOCUS:    LOGI("--> CMD %d : Lost focus \n",cmd);
//    lost_focus(e);
    break;
    case APP_CMD_WINDOW_RESIZED:LOGI("--> CMD %d : Resize win \n",cmd);    break;
    
    case APP_CMD_SAVE_STATE:    LOGI("--> CMD %d : Save state \n",cmd);        
        app->savedState = (struct engine *)malloc(sizeof(struct engine));
        memcpy(app->savedState,app->userData,sizeof(struct engine));
        app->savedStateSize = sizeof(struct engine);
        break;
    case APP_CMD_PAUSE:         LOGI("--> CMD %d : Pause \n",cmd);         break;
    case APP_CMD_STOP:          LOGI("--> CMD %d : Stop \n",cmd);          break;    
    case APP_CMD_TERM_WINDOW:   LOGI("--> CMD %d : Term win. \n",cmd);
//    term_window(e);
    break;

    case APP_CMD_CONFIG_CHANGED:LOGI("--> CMD %d : Config changed \n",cmd);break;
    case APP_CMD_WINDOW_REDRAW_NEEDED:LOGI("--> CMD %d : Redraw needed \n",cmd); break;
    case APP_CMD_GAINED_FOCUS:  LOGI("--> CMD %d : Gained focus \n",cmd);
    
    break;
    
    default:                    LOGI("--> CMD %d : Je ne sais pas ! \n",cmd);
  }
}

static int32_t input_android(struct android_app* app,AInputEvent* event)
{ int32_t key;
  int idx,x,y,mouse_id;
  float cx,cy;
  if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
    
    //LOGI("%7.2f \n",event->motionMaxX);AINPUT_MOTION_RANGE_X
    
    key = AMotionEvent_getAction(event);
    idx = (key & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> 
    AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;    
    if (AConfiguration_getOrientation(app->config) == 1) { // 1=Portrait
      cx = 320.0/ANativeWindow_getWidth(app->window);
    } else { //2=Landscape
      cx = 320.0/ANativeWindow_getHeight(app->window);
    };
    //AMotionEvent_getXPrecision(event);
    cy = cx;    
    //AMotionEvent_getYPrecision(event);
    switch (key & AMOTION_EVENT_ACTION_MASK) {
      case AMOTION_EVENT_ACTION_DOWN: 
        x = (int)((float)AMotionEvent_getX(event,0) / cx);
        y = (int)((float)AMotionEvent_getY(event,0) / cy);
        /*
        LOGI("x=%7.2f y=%7.2f\n",AMotionEvent_getX(event,0),AMotionEvent_getY(event,0));        
        LOGI("x=%7.2f y=%7.2f\n",AMotionEvent_getRawX(event,0),AMotionEvent_getRawY(event,0));
        
        LOGI("size=%7.2f\n",AMotionEvent_getAxisValue(event,AINPUT_MOTION_RANGE_X,0));
        LOGI("size=%7.2f\n",AMotionEvent_getAxisValue(event,AINPUT_MOTION_RANGE_Y,0));
        LOGI("size=%7.2f\n",AMotionEvent_getAxisValue(event,2,0));
        LOGI("size=%7.2f\n",AMotionEvent_getAxisValue(event,3,0));
        LOGI("preciX=%7.2f\n",AMotionEvent_getXPrecision(event));
        LOGI("preciY=%7.2f\n",AMotionEvent_getYPrecision(event));
        //LOGI("x=%7.2f \n",event.touch.x.max); //AMotionEvent_getXMax(event,0));
        */
        /*
        { float xmin,xmax,ymin,ymax;
          Activity_GetDeviceMotionRange(deviceId,AINPUT_SOURCE_TOUCHSCREEN,&xmin,&xmax,&ymin,&ymax);
          AINPUT_MOTION_RANGE_SIZE

        // &(newItem->minY), &(newItem->maxY));
        LOGI("x=%7.2f,%7.2f y=%7.2f,%7.2f\n",xmin,xmax,ymin,ymax);
        };*/
        /*
        for (int i = 0; i < _motion_range_cache_items; i++) {
          DeviceMotionRange *item = &_motion_range_cache[i];          
          if (item->deviceId == deviceId && item->source == source) {
            *outMinX = item->minX;
            *outMaxX = item->maxX;
            *outMinY = item->minY;
            *outMaxY = item->maxY;
            return;
            } 
        }*/
        //LOGI("size = %f %f\n",AMotionEvent_getAxisValue(event,0,0),cy);
        mouse_action (app->userData,0,1,x,y);
        break;    
      case AMOTION_EVENT_ACTION_POINTER_DOWN:         
        x = (int)((float)AMotionEvent_getX(event,idx) / cx);
        y = (int)((float)AMotionEvent_getY(event,idx) / cy);
        mouse_id = AMotionEvent_getPointerId(event,idx);
        //LOGI("id ptr dwn = %d\n",mouse_id);
        if ((mouse_id>=0) && (mouse_id<10)) { 
          mouse_action (app->userData,mouse_id,1,x,y);        
        };
        break;
      case AMOTION_EVENT_ACTION_UP: 
        x = (int)((float)AMotionEvent_getX(event,0) / cx);
        y = (int)((float)AMotionEvent_getY(event,0) / cy);
        //LOGI("scr %f %f\n",AMotionEvent_getXPrecision(event),AMotionEvent_getYPrecision(event));
        mouse_id = AMotionEvent_getPointerId(event,0);
        //LOGI("id up = %d\n",mouse_id);        
        if ((mouse_id>=0) && (mouse_id<10)) { 
          mouse_action (app->userData,mouse_id,0,x,y);
        };
        break;    
      case AMOTION_EVENT_ACTION_POINTER_UP: 
        x = (int)((float)AMotionEvent_getX(event,idx) / cx);
        y = (int)((float)AMotionEvent_getY(event,idx) / cy);
        //LOGI("scr %d %d\n",x,y);
        mouse_id = AMotionEvent_getPointerId(event,idx);
        //LOGI("id ptr up = %d\n",mouse_id);        
        if ((mouse_id>=0) && (mouse_id<10)) { 
          mouse_action (app->userData,mouse_id,0,x,y);        
        };
        break;
      case AMOTION_EVENT_ACTION_MOVE:        
        for (idx=0;idx<AMotionEvent_getPointerCount(event);idx++) {
          mouse_id = AMotionEvent_getPointerId(event,idx);           
          x = (int)((float)AMotionEvent_getX(event,idx) / cx);
          y = (int)((float)AMotionEvent_getY(event,idx) / cy);          
          if ((mouse_id>=0) && (mouse_id<10)) { 
            mouse_action (app->userData,mouse_id,-1,x,y);                    
          };
        };  
        break;
      case AMOTION_EVENT_ACTION_OUTSIDE:        
      case AMOTION_EVENT_ACTION_CANCEL:        
        break;
    };
  }
  return 0;
}

// Begin Sensor
#include <dlfcn.h>
const char*  kPackageName = "com.android.accelerometergraph";
ASensorManager* AcquireASensorManagerInstance(void) {
    typedef ASensorManager *(*PF_GETINSTANCEFORPACKAGE)(const char *name);
    void* androidHandle = dlopen("libandroid.so", RTLD_NOW);
    PF_GETINSTANCEFORPACKAGE getInstanceForPackageFunc = (PF_GETINSTANCEFORPACKAGE)
        dlsym(androidHandle, "ASensorManager_getInstanceForPackage");
    if (getInstanceForPackageFunc) {
        return getInstanceForPackageFunc(kPackageName);
    }

    typedef ASensorManager *(*PF_GETINSTANCE)();
    PF_GETINSTANCE getInstanceFunc = (PF_GETINSTANCE)
        dlsym(androidHandle, "ASensorManager_getInstance");
    // by all means at this point, ASensorManager_getInstance should be available
    if (getInstanceFunc == NULL) LOGI("getInstanceFunc NULL");
    return getInstanceFunc();
}
// End Sensor

void android_main(struct android_app* state) {
  struct engine e;
  pthread_t t;
  ASensorManager *sensorManager;
  ALooper *looper;
  int status;  
  
  my_app = state; // Used by AssetManager_Open
  
  //if (state->userData != NULL) return;
  if (state->savedState == NULL) {
    LOGI("----------- PAPER FIRST RUN -----\n");
    //e = (struct engine *)malloc(sizeof(struct engine));
    e.pen = NULL;    
  } else {
    LOGI("----------- PAPER RELOAD --------\n");
    memcpy(&e,(struct engine *)state->savedState,sizeof(struct engine));
    free(state->savedState);
    //e = state->savedState;
    state->savedState = NULL;
    state->savedStateSize = 0;    
  };
  LOGI("Adress UserData %p\n",&e);  
  state->userData = &e;  
  state->onAppCmd = cmd_android;
  state->onInputEvent = input_android;
  e.app = state;
  if (e.pen == NULL) {
    LOGI("****************** MAIN ********************\n");
    main(0,NULL);      
  };
  
  sensorManager = AcquireASensorManagerInstance();
  if (sensorManager == NULL) LOGI("SensorManager NULL");
  // Begin Accelerometer
  { const ASensor *accelerometer;        
    accelerometer = ASensorManager_getDefaultSensor(sensorManager, ASENSOR_TYPE_ACCELEROMETER);
    if (accelerometer == NULL) LOGI("accelerometer NULL");
    looper = ALooper_prepare(ALOOPER_PREPARE_ALLOW_NON_CALLBACKS);
    if (looper == NULL) LOGI("looper NULL");
    accelerometerEventQueue = ASensorManager_createEventQueue(sensorManager, looper,
    LOOPER_ID_USER, NULL, NULL);
    if (accelerometerEventQueue == NULL) LOGI("accelerometerEventQueue NULL");
    status = ASensorEventQueue_enableSensor(accelerometerEventQueue, accelerometer);
    if (status < 0) LOGI("1) status < 0");
    status = ASensorEventQueue_setEventRate(accelerometerEventQueue, accelerometer,
    SENSOR_REFRESH_PERIOD_US);
    if (status < 0) LOGI("2) status < 0");
  };
  // End Accelerometer
    
  LOGI("Create Thread\n");
  while (1) {
    int ident, events;
    struct android_poll_source* source;
    while ((ident=ALooper_pollAll(0, NULL, &events, (void**)&source)) >= 0) {
      if (source != NULL) {        
	source->process(state, source);
      }
      if (e.stat == APP_CMD_GAINED_FOCUS) {        
        draw_in(&e);
      };
      //  LOGI("++> %d\n",events);
      if (state->destroyRequested != 0) { 
        LOGI("Exit\n");
	return;
      }
    }
  }
}
