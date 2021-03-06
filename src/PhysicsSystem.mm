#import "PhysicsSystem.h"
#import "CCDraggableSprite.h"

PhysicsSystem::PhysicsSystem (): fixedTimestepAccumulator_ (0), fixedTimestepAccumulatorRatio_ (0),velocityIterations_(8), positionIterations_(8)
{
	// ...
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
}

b2World* PhysicsSystem::getWorld(void) {
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
	return world_;
}

void PhysicsSystem::setWorld(b2World* world) {
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
	world_ = world;
    targetLayer = nil;
    selectorLayer = nil;
}

PhysicsSystem::~PhysicsSystem (void) {
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
	CCLOG(@"DESTRUCTING PHYSICS...");
}

void PhysicsSystem::update (float dt)
{
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
	// Maximum number of steps, to avoid degrading to an halt.
	const int MAX_STEPS = 12;
    
	fixedTimestepAccumulator_ += dt;
	const int nSteps = static_cast<int> (
										 std::floor (fixedTimestepAccumulator_ / FIXED_TIMESTEP)
										 );
	// To avoid rounding errors, touches fixedTimestepAccumulator_ only
	// if needed.
	if (nSteps > 0)
	{
		fixedTimestepAccumulator_ -= nSteps * FIXED_TIMESTEP;
	}
    
	assert (
			"Accumulator must have a value lesser than the fixed time step" &&
			fixedTimestepAccumulator_ < FIXED_TIMESTEP + FLT_EPSILON
			);
	fixedTimestepAccumulatorRatio_ = fixedTimestepAccumulator_ / FIXED_TIMESTEP;
    
	// This is similar to clamp "dt":
	//	dt = std::min (dt, MAX_STEPS * FIXED_TIMESTEP)
	// but it allows above calculations of fixedTimestepAccumulator_ and
	// fixedTimestepAccumulatorRatio_ to remain unchanged.
	const int nStepsClamped = std::min (nSteps, MAX_STEPS);
	for (int i = 0; i < nStepsClamped; ++ i)
	{
        /*
        if(i == nStepsClamped-1) {
            
        }
        */
        
		// In singleStep_() the CollisionManager could fire custom
		// callbacks that uses the smoothed states. So we must be sure
		// to reset them correctly before firing the callbacks.
		resetSmoothStates_ ();
		singleStep_ (FIXED_TIMESTEP);
	}
    
    //smoothStates_ is not necessary anymore, smooth states calculation and sprite position update
    //are both performed at the same time with the syncPhysicsSprites method of WorldPhysics.
}

void PhysicsSystem::singleStep_ (float dt)
{
	// ...
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
    
	//updateControllers_ (dt);
    if ([targetLayer respondsToSelector:selectorLayer]) {
        [targetLayer performSelector:selectorLayer];
    }
    
    if (world_ != NULL) {
        world_->Step (dt, velocityIterations_, positionIterations_);
    }
	//consumeContacts_ ();
    
	// ...
}

void PhysicsSystem::registerAnimationCallBack (id target, SEL selector)
{
    CCLOG(@"Base class, %s", __PRETTY_FUNCTION__);
    if (targetLayer != target && selector && target) {
        targetLayer = target;
        selectorLayer = selector;
    }
}

void PhysicsSystem::resetSmoothStates_ ()
{
    if (world_ == NULL) {
        return;
    }
    
	b2Vec2 newSmoothedPosition;
    
	for (b2Body * b = world_->GetBodyList (); b != NULL; b = b->GetNext ())
	{
		if (b->GetType () == b2_staticBody)
		{
			continue;
		}
        
		CCDraggableSprite *c   = (__bridge CCDraggableSprite*) b->GetUserData();
        
		newSmoothedPosition = b->GetPosition ();
        
        //Coarse grained safety check...
        if([c respondsToSelector:@selector(setSmoothedPosition:)]) {
            CCLOG(@"Base class, smoothing OK, %s", __PRETTY_FUNCTION__);
            
            c.smoothedPosition = newSmoothedPosition;
            c.previousPosition = newSmoothedPosition;
            c.smoothedAngle = b->GetAngle ();
            c.previousAngle = b->GetAngle();
        }
	}
}

float PhysicsSystem::getFixedTimestep() {
    return FIXED_TIMESTEP;
}

float PhysicsSystem::getFixedTimestepAccumulator() {
    return this->fixedTimestepAccumulator_;
}

float PhysicsSystem::getFixedTimestepAccumulatorRatio() {
    return this->fixedTimestepAccumulatorRatio_;
}
