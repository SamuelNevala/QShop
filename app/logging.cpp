#include "logging.h"

#include <QtCore/QLoggingCategory>
#include <QtCore/QtLogging>

namespace {
#ifdef QT_NO_DEBUG
constexpr QtMsgType kDefaultLogLevel = QtWarningMsg;
#else
constexpr QtMsgType kDefaultLogLevel = QtDebugMsg;
#endif
} // namespace

Q_LOGGING_CATEGORY(qshopperAppLog, "qshopper.app", kDefaultLogLevel)
Q_LOGGING_CATEGORY(qshopperModelLog, "qshopper.model", kDefaultLogLevel)
