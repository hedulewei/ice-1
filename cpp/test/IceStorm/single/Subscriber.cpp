// **********************************************************************
//
// Copyright (c) 2003
// ZeroC, Inc.
// Billerica, MA, USA
//
// All Rights Reserved.
//
// Ice is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License version 2 as published by
// the Free Software Foundation.
//
// **********************************************************************

#include <Ice/Ice.h>
#include <IceStorm/IceStorm.h>
#include <Single.h>

#ifdef _WIN32
#   include <io.h>
#else
#   include <sys/types.h>
#   include <sys/stat.h>
#   include <fcntl.h>
#endif

using namespace std;
using namespace Ice;
using namespace IceStorm;

class SingleI : public Single
{
public:

    SingleI(const CommunicatorPtr& communicator) :
	_communicator(communicator),
	_count(0)
    {
    }

    virtual void event(const Current&)
    {
	++_count;
	if(_count == 10)
	{
	    _communicator->shutdown();
	}
    }

private:

    CommunicatorPtr _communicator;
    int _count;
};

void
createLock(const string& name)
{
#ifdef _WIN32
    int ret = _open(name.c_str(), O_CREAT | O_WRONLY | O_EXCL);
#else
    int ret = open(name.c_str(), O_CREAT | O_WRONLY | O_EXCL);
#endif
    assert(ret != -1);
}

void
deleteLock(const string& name)
{
#ifdef _WIN32
    int ret = _unlink(name.c_str());
#else
    int ret = unlink(name.c_str());
#endif
    assert(ret != -1);
}

int
run(int argc, char* argv[], const CommunicatorPtr& communicator)
{
    string lockfile = "subscriber.lock";

    if(argc != 1)
    {
	lockfile = argv[1];
    }

    createLock(lockfile);

    PropertiesPtr properties = communicator->getProperties();
    const char* managerProxyProperty = "IceStorm.TopicManager.Proxy";
    string managerProxy = properties->getProperty(managerProxyProperty);
    if(managerProxy.empty())
    {
	cerr << argv[0] << ": property `" << managerProxyProperty << "' is not set" << endl;
	return EXIT_FAILURE;
    }

    ObjectPrx base = communicator->stringToProxy(managerProxy);
    IceStorm::TopicManagerPrx manager = IceStorm::TopicManagerPrx::checkedCast(base);
    if(!manager)
    {
	cerr << argv[0] << ": `" << managerProxy << "' is not running" << endl;
	return EXIT_FAILURE;
    }

    ObjectAdapterPtr adapter = communicator->createObjectAdapterWithEndpoints("SingleAdapter", "default");
    ObjectPtr single = new SingleI(communicator);
    ObjectPrx object = adapter->addWithUUID(single);

    IceStorm::QoS qos;
    //TODO: qos["reliability"] = "batch";
    try
    {
        TopicPrx topic = manager->retrieve("single");
	topic->subscribe(qos, object);
    }
    catch(const IceStorm::NoSuchTopic& e)
    {
	cerr << argv[0] << ": NoSuchTopic: " << e.name << endl;
	return EXIT_FAILURE;
    }

    adapter->activate();

    communicator->waitForShutdown();

    deleteLock(lockfile);

    return EXIT_SUCCESS;
}

int
main(int argc, char* argv[])
{
    int status;
    CommunicatorPtr communicator;

    try
    {
	communicator = initialize(argc, argv);
	status = run(argc, argv, communicator);
    }
    catch(const Exception& ex)
    {
	cerr << ex << endl;
	status = EXIT_FAILURE;
    }

    if(communicator)
    {
	try
	{
	    communicator->destroy();
	}
	catch(const Exception& ex)
	{
	    cerr << ex << endl;
	    status = EXIT_FAILURE;
	}
    }

    return status;
}
