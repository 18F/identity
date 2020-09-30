import React, { useState, useContext } from 'react';
import { Alert } from '@18f/identity-components';
import FormSteps from './form-steps';
import { UploadFormEntriesError } from '../services/upload';
import DocumentsStep from './documents-step';
import SelfieStep from './selfie-step';
import ReviewIssuesStep from './review-issues-step';
import MobileIntroStep from './mobile-intro-step';
import DeviceContext from '../context/device';
import ServiceProviderContext from '../context/service-provider';
import Submission from './submission';
import DesktopDocumentDisclosure from './desktop-document-disclosure';
import useI18n from '../hooks/use-i18n';

/** @typedef {import('react').ReactNode} ReactNode */
/** @typedef {import('./form-steps').FormStep} FormStep */
/** @typedef {import('../context/upload').UploadFieldError} UploadFieldError */

/**
 * Returns error messages interspersed with line break React element.
 *
 * @param {UploadFieldError[]} errors Error messages.
 *
 * @return {ReactNode[]} Formatted error messages.
 */
export function getFormattedErrorMessages(errors) {
  return errors.flatMap((error, i) => [<br key={i} />, error.message]).slice(1);
}

function DocumentCapture() {
  const [formValues, setFormValues] = useState(/** @type {Record<string,any>?} */ (null));
  const [submissionError, setSubmissionError] = useState(/** @type {Error?} */ (null));
  const { t } = useI18n();
  const { isMobile } = useContext(DeviceContext);
  const serviceProvider = useContext(ServiceProviderContext);

  /**
   * Clears error state and sets form values for submission.
   *
   * @param {Record<string,any>} nextFormValues Submitted form values.
   */
  function submitForm(nextFormValues) {
    setSubmissionError(null);
    setFormValues(nextFormValues);
  }

  const isFormEntriesError = submissionError && submissionError instanceof UploadFormEntriesError;

  /** @type {FormStep[]} */
  const steps = submissionError
    ? [
        {
          name: 'review',
          title: t('doc_auth.headings.review_issues'),
          form: ReviewIssuesStep,
          footer: DesktopDocumentDisclosure,
        },
      ]
    : /** @type {FormStep[]} */ ([
        isMobile && {
          name: 'intro',
          title: t('doc_auth.headings.document_capture'),
          form: MobileIntroStep,
        },
        {
          name: 'documents',
          title: t('doc_auth.headings.document_capture'),
          form: DocumentsStep,
          footer: DesktopDocumentDisclosure,
        },
        serviceProvider?.isLivenessRequired !== false && {
          name: 'selfie',
          title: t('doc_auth.headings.selfie'),
          form: SelfieStep,
        },
      ].filter(Boolean));

  return formValues && !submissionError ? (
    <Submission
      payload={formValues}
      onError={(nextSubmissionError) => setSubmissionError(nextSubmissionError)}
    />
  ) : (
    <>
      {submissionError && (
        <Alert type="error" className="margin-bottom-4 margin-top-2 tablet:margin-top-0">
          {isFormEntriesError
            ? getFormattedErrorMessages(
                /** @type {UploadFormEntriesError} */ (submissionError).rawErrors,
              )
            : t('errors.doc_auth.acuant_network_error')}
        </Alert>
      )}
      <FormSteps
        steps={steps}
        initialValues={submissionError && formValues ? formValues : undefined}
        onComplete={submitForm}
        autoFocus={!!submissionError}
      />
    </>
  );
}

export default DocumentCapture;
